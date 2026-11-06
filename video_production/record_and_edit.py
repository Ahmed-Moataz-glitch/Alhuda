"""
Alhuda App - Full Video Production Script
Records each section, merges with voiceover, adds title overlay, then concatenates all.
"""

import subprocess, time, os, json, glob, threading

ADB  = r'C:\Users\Ahmed\AppData\Local\Android\Sdk\platform-tools\adb.exe'
ROOT = r'd:\Flutter Projects\alhuda\video_production'

os.makedirs(ROOT + '/clips', exist_ok=True)
os.makedirs(ROOT + '/merged', exist_ok=True)

# -------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------
def adb(*args):
    return subprocess.run([ADB, '-s', 'emulator-5554', 'shell'] + list(args))

def pull(remote, local):
    subprocess.run([ADB, '-s', 'emulator-5554', 'pull', remote, local])

def tap(x, y):
    adb('input', 'tap', str(x), str(y))

def swipe(x1, y1, x2, y2, d=400):
    adb('input', 'swipe', str(x1), str(y1), str(x2), str(y2), str(d))

def back():
    adb('input', 'keyevent', '4')

def launch_app():
    subprocess.run([ADB, '-s', 'emulator-5554', 'shell', 'monkey', '-p',
                    'dev.glitch.alhuda', '-c', 'android.intent.category.LAUNCHER', '1'],
                   capture_output=True)
    time.sleep(2)
    swipe(540, 400, 540, 1900, 200)
    time.sleep(1)

def get_audio_duration(path):
    cmd = ['ffprobe', '-v', 'quiet', '-show_entries', 'format=duration', '-of', 'json', path]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return float(json.loads(res.stdout)['format']['duration'])

def record_device(remote_path, local_path, duration):
    """Start screenrecord in background, wait duration+2s, stop, pull."""
    proc = subprocess.Popen(
        [ADB, '-s', 'emulator-5554', 'shell',
         'screenrecord', '--bit-rate', '8M', '--time-limit', str(int(duration) + 3),
         remote_path],
    )
    return proc

def stop_recording_and_pull(proc, remote_path, local_path, duration):
    time.sleep(duration)
    # Send Ctrl+C to kill screenrecord
    proc.terminate()
    time.sleep(2)
    pull(remote_path, local_path)

def merge_clip_audio(video_path, audio_path, out_path, title_text):
    """Merge video+audio, add title overlay text."""
    # Pad or trim video to exact audio duration
    audio_dur = get_audio_duration(audio_path)
    
    # Build safe title for drawtext (escape colons and quotes)
    safe_title = title_text.replace("'", "\\'").replace(":", "\\:")

    # FFmpeg: loop/trim video to audio duration, overlay title, merge audio
    filter_complex = (
        f"[0:v]loop=loop=-1:size=999999:start=0,trim=duration={audio_dur},setpts=PTS-STARTPTS,"
        f"drawtext=font='Arial':fontfile='C\\:/Windows/Fonts/arial.ttf':"
        f"text='{safe_title}':"
        f"fontcolor=white:fontsize=36:box=1:boxcolor=black@0.55:boxborderw=12:"
        f"x=(w-text_w)/2:y=h-90:enable='between(t,0,{audio_dur})'[v]"
    )

    cmd = [
        'ffmpeg', '-y',
        '-i', video_path,
        '-i', audio_path,
        '-filter_complex', filter_complex,
        '-map', '[v]',
        '-map', '1:a',
        '-c:v', 'libx264', '-preset', 'fast', '-crf', '22',
        '-c:a', 'aac', '-b:a', '128k',
        '-t', str(audio_dur),
        out_path
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f'FFmpeg error: {result.stderr[-500:]}')
    else:
        print(f'  => Merged: {out_path}')

# -------------------------------------------------------------------
# Section definitions: (id, audio_key, title_text, actions_fn)
# -------------------------------------------------------------------

def navigate_to_home():
    launch_app()

def actions_intro():
    """Home page - scroll slowly to show features"""
    swipe(540, 400, 540, 1900, 200)
    time.sleep(1.5)
    swipe(540, 900, 540, 200, 800)
    time.sleep(2)

def actions_quran():
    """Go to Quran, show surah list"""
    back(); back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    # Tap Quran card (top right at ~750, 750 in home)
    tap(720, 900)
    time.sleep(2)
    # scroll surah list
    swipe(540, 900, 540, 400, 600)
    time.sleep(1)
    swipe(540, 900, 540, 400, 600)
    time.sleep(1)

def actions_tafseer():
    """Open surah Baqarah, show mushaf, then tafseer"""
    # Already in Quran — go back to list and tap surah
    back()
    time.sleep(1)
    swipe(540, 400, 540, 1900, 200)
    time.sleep(1)
    # tap Al-Baqarah row (y≈1170 in surah list)
    tap(400, 1170)
    time.sleep(3)
    # Tap center to show toolbar
    tap(540, 900)
    time.sleep(1)
    # Tap 'تفسير الصفحة' button y=1870
    tap(420, 1870)
    time.sleep(2)
    # scroll tafseer
    swipe(540, 900, 540, 300, 700)
    time.sleep(1)

def actions_prayer():
    """Open Prayer Times"""
    back(); back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    # prayer times card (bottom-right area in home grid, ~x=720, y=1200)
    tap(720, 1200)
    time.sleep(2)
    # scroll down slightly
    swipe(540, 900, 540, 400, 600)
    time.sleep(1)

def actions_qibla():
    """Open Qibla"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    swipe(540, 400, 540, 200, 300)
    time.sleep(1)
    # Qibla card (bottom-right)
    tap(720, 2000)
    time.sleep(3)

def actions_hadith():
    """Open Hadith section"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    # Hadith is top-left card after quran
    tap(250, 900)
    time.sleep(2)
    swipe(540, 900, 540, 300, 700)
    time.sleep(1)
    swipe(540, 900, 540, 300, 700)
    time.sleep(1)

def actions_azkar():
    """Open Azkar"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    swipe(540, 900, 540, 400, 500)
    time.sleep(1)
    tap(250, 1100)
    time.sleep(2)
    # scroll azkar list
    swipe(540, 900, 540, 300, 600)
    time.sleep(1)

def actions_tasbeeh():
    """Open Tasbeeh / digital rosary"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    swipe(540, 900, 540, 400, 500)
    time.sleep(1)
    tap(720, 1100)
    time.sleep(2)
    # tap a few times to simulate tasbih
    for _ in range(5):
        tap(540, 1000)
        time.sleep(0.4)

def actions_calendar():
    """Open Hijri Calendar"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    swipe(540, 900, 540, 400, 500)
    time.sleep(1)
    tap(250, 1550)
    time.sleep(2)
    swipe(540, 900, 540, 300, 600)
    time.sleep(1)

def actions_allah_names():
    """Open Allah Names"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    swipe(540, 900, 540, 200, 500)
    time.sleep(1)
    tap(720, 1850)
    time.sleep(2)
    swipe(540, 900, 540, 300, 600)
    time.sleep(1)

def actions_fiqh():
    """Open Fiqh section"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    swipe(540, 900, 540, 200, 500)
    time.sleep(1)
    tap(250, 1850)
    time.sleep(2)
    swipe(540, 900, 540, 300, 600)
    time.sleep(1)

def actions_outro():
    """Show dark mode toggle + guide page"""
    back(); back()
    time.sleep(1)
    launch_app()
    time.sleep(1)
    # tap theme button (top-left)
    tap(110, 105)
    time.sleep(1.5)
    # show app in dark mode
    swipe(540, 600, 540, 200, 500)
    time.sleep(1.5)
    # toggle back to light
    tap(110, 105)
    time.sleep(1)
    # scroll down to guide card
    swipe(540, 400, 540, 200, 400)
    time.sleep(1)

SECTIONS = [
    ('01_intro',       'المقدمة — تطبيق الهُدى',         actions_intro),
    ('02_quran',       'المصحف الشريف — السور والأجزاء',  actions_quran),
    ('03_tafseer',     'التفسير الميسر والبحث',            actions_tafseer),
    ('04_prayer',      'مواقيت الصلاة والأذان',            actions_prayer),
    ('05_qibla',       'القبلة — بوصلة وطريقة الشمس',     actions_qibla),
    ('06_hadith',      'الأحاديث النبوية',                 actions_hadith),
    ('07_azkar',       'حصن المسلم — أذكار اليوم والليلة', actions_azkar),
    ('08_tasbeeh',     'التسبيح الحر والسبحة الإلكترونية', actions_tasbeeh),
    ('09_calendar',    'التقويم الهجري وأطوار القمر',      actions_calendar),
    ('10_allah_names', 'أسماء الله الحسنى — ٩٩ اسماً',   actions_allah_names),
    ('11_fiqh',        'الفقه الإسلامي الميسر',           actions_fiqh),
    ('12_outro',       'دليل المميزات والوضع الليلي',      actions_outro),
]

# -------------------------------------------------------------------
# MAIN: record & merge each section
# -------------------------------------------------------------------
print('=== Starting Recording Session ===')
launch_app()
time.sleep(2)

for sec_id, title, action_fn in SECTIONS:
    audio_path  = f'{ROOT}/audio/{sec_id}.mp3'
    raw_video   = f'{ROOT}/clips/{sec_id}_raw.mp4'
    remote_mp4  = f'/sdcard/{sec_id}.mp4'
    merged_path = f'{ROOT}/merged/{sec_id}.mp4'

    if not os.path.exists(audio_path):
        print(f'[SKIP] Missing audio for {sec_id}')
        continue

    audio_dur = get_audio_duration(audio_path)
    print(f'\n[{sec_id}] Recording {audio_dur:.1f}s — "{title}"')

    # Start screen recording on device
    rec_proc = record_device(remote_mp4, raw_video, audio_dur)
    time.sleep(1.5)  # give screenrecord a moment to start

    # Run UI actions during recording
    action_fn()

    # Wait remaining time then stop
    elapsed = audio_dur - 1.5
    remaining = elapsed - 8  # approximate action time
    if remaining > 0:
        time.sleep(remaining)

    rec_proc.terminate()
    time.sleep(2)

    print(f'  Pulling clip...')
    pull(remote_mp4, raw_video)
    time.sleep(1)

    if os.path.exists(raw_video) and os.path.getsize(raw_video) > 10000:
        merge_clip_audio(raw_video, audio_path, merged_path, title)
    else:
        print(f'  [ERROR] Raw video missing or too small: {raw_video}')

# -------------------------------------------------------------------
# Concatenate all merged clips
# -------------------------------------------------------------------
print('\n=== Concatenating all clips ===')
concat_list = f'{ROOT}/concat_list.txt'
merged_files = sorted(glob.glob(f'{ROOT}/merged/*.mp4'))

with open(concat_list, 'w', encoding='utf-8') as f:
    for mf in merged_files:
        f.write(f"file '{mf}'\n")

final_output = f'{ROOT}/alhuda_app_tour.mp4'
cmd = [
    'ffmpeg', '-y',
    '-f', 'concat', '-safe', '0',
    '-i', concat_list,
    '-c:v', 'libx264', '-preset', 'fast', '-crf', '20',
    '-c:a', 'aac', '-b:a', '128k',
    '-movflags', '+faststart',
    final_output
]
result = subprocess.run(cmd, capture_output=True, text=True)
if result.returncode == 0:
    size_mb = os.path.getsize(final_output) / 1024 / 1024
    print(f'\n✅ Final video ready: {final_output}')
    print(f'   Size: {size_mb:.1f} MB')
else:
    print(f'Concat error: {result.stderr[-800:]}')
