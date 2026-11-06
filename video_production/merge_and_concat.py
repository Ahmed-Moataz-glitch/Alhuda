# -*- coding: utf-8 -*-
"""
Fixed merge: use -stream_loop instead of loop filter, fix concat paths.
"""
import subprocess, json, os, glob

ROOT = r'd:/Flutter Projects/alhuda/video_production'

def get_audio_duration(path):
    cmd = ['ffprobe', '-v', 'quiet', '-show_entries', 'format=duration', '-of', 'json', path]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return float(json.loads(res.stdout)['format']['duration'])

def merge_clip_audio(video_path, audio_path, out_path, title_text):
    audio_dur = get_audio_duration(audio_path)
    
    # Use -stream_loop -1 to loop video input, trim to audio duration
    # drawtext with Windows Arial font (no Arabic needed - use latin fallback title)
    # We skip Arabic drawtext to avoid font issues, just merge video+audio cleanly
    cmd = [
        'ffmpeg', '-y',
        '-stream_loop', '-1', '-i', video_path,
        '-i', audio_path,
        '-map', '0:v:0',
        '-map', '1:a:0',
        '-c:v', 'libx264', '-preset', 'fast', '-crf', '22',
        '-c:a', 'aac', '-b:a', '128k',
        '-t', str(audio_dur),
        '-movflags', '+faststart',
        out_path
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f'  [ERROR] {result.stderr[-300:]}')
        return False
    print(f'  => OK: {out_path}')
    return True

SECTIONS = [
    '01_intro', '02_quran', '03_tafseer', '04_prayer',
    '05_qibla', '06_hadith', '07_azkar', '08_tasbeeh',
    '09_calendar', '10_allah_names', '11_fiqh', '12_outro'
]

os.makedirs(f'{ROOT}/merged', exist_ok=True)
merged_files = []

for sec_id in SECTIONS:
    raw_video  = f'{ROOT}/clips/{sec_id}_raw.mp4'
    audio_path = f'{ROOT}/audio/{sec_id}.mp3'
    out_path   = f'{ROOT}/merged/{sec_id}.mp4'

    if not os.path.exists(raw_video):
        print(f'[SKIP - no raw video] {sec_id}')
        continue
    if not os.path.exists(audio_path):
        print(f'[SKIP - no audio] {sec_id}')
        continue

    dur = get_audio_duration(audio_path)
    print(f'[{sec_id}] audio={dur:.1f}s video={os.path.getsize(raw_video)//1024}KB')

    ok = merge_clip_audio(raw_video, audio_path, out_path, sec_id)
    if ok:
        merged_files.append(out_path)

# ---- Concatenate ----
print(f'\n=== Concatenating {len(merged_files)} clips ===')

concat_list = f'{ROOT}/concat_list.txt'
with open(concat_list, 'w', encoding='utf-8') as f:
    for mf in sorted(merged_files):
        # Use forward slashes, wrap in single quotes
        safe = mf.replace('\\', '/')
        f.write(f"file '{safe}'\n")

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
    dur_cmd = ['ffprobe', '-v', 'quiet', '-show_entries', 'format=duration', '-of', 'json', final_output]
    dur_res = subprocess.run(dur_cmd, capture_output=True, text=True)
    total_dur = float(json.loads(dur_res.stdout)['format']['duration'])
    print(f'\nFinal video: {final_output}')
    print(f'Duration: {total_dur:.0f}s ({total_dur/60:.1f} min) | Size: {size_mb:.1f} MB')
else:
    print(f'Concat error:\n{result.stderr[-600:]}')
