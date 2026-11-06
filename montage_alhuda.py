"""
Production Montage Script for Alhuda App Guide Video
1. Uses Edge TTS (ar-SA-HamedNeural) for authentic Saudi voiceover
2. Extracts and trims precise, glitch-free clips from D:\alhuda.mp4
3. Synchronizes each clip with its voiceover
4. Re-encodes with optimal compression (libx264 CRF 23, AAC 128k)
5. Concatenates into a seamless master video
"""

import asyncio, edge_tts, json, os, subprocess, glob, shutil

ROOT = r'd:/Flutter Projects/alhuda'
RAW_VIDEO = r'D:\alhuda.mp4'
TEMP_DIR = f'{ROOT}/video_montage_temp'
OUTPUT_DIR = f'{ROOT}/assets/video'
FINAL_TARGET = f'{OUTPUT_DIR}/app_guide.mp4'
VOICE = 'ar-SA-HamedNeural'

os.makedirs(f'{TEMP_DIR}/audio', exist_ok=True)
os.makedirs(f'{TEMP_DIR}/raw_clips', exist_ok=True)
os.makedirs(f'{TEMP_DIR}/uniform_clips', exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

SECTIONS = [
    {
        'id': '01_intro',
        'title': 'المقدمة والواجهة الرئيسية',
        'text': 'بسم الله الرحمن الرحيم. مرحباً بكم في تطبيق الهُدى، رفيقك الإسلامي المتكامل الذي يجمع لك كل ما تحتاجه في يومك وليلتك، بواجهة عصرية وتصميم إيماني هادئ.',
        'cuts': [(2.0, 7.5), (19.2, 29.0)]
    },
    {
        'id': '02_quran',
        'title': 'المصحف الشريف والتفسير',
        'text': 'المصحف الشريف برسم عثماني واضح مع تلوين أحكام التجويد، وإمكانية الاستماع لتلاوات خاشعة، وقراءة التفسير الميسر، والتنقل السلس بين السور والأجزاء.',
        'cuts': [(92.5, 98.5), (116.5, 124.3)]
    },
    {
        'id': '03_hadith',
        'title': 'الأحاديث النبوية الشريفة',
        'text': 'مكتبة وافية للسنة النبوية الشريفة تضم صحيح البخاري، وصحيح مسلم، والأربعين النووية، مع ميزة البحث الفوري والتحكم بحجم الخط لقراءة مريحة.',
        'cuts': [(142.0, 155.5)]
    },
    {
        'id': '04_prayer',
        'title': 'مواقيت الصلاة والأذان',
        'text': 'مواقيت صلاة دقيقة لمدينتك مع تنبيهات الأذان بصوت نخبة من كبار المؤذنين، وتخصيص التنبيهات المسبقة، وحساب المواقيت وفق أهم الهيئات الإسلامية.',
        'cuts': [(182.0, 195.0)]
    },
    {
        'id': '05_calendar',
        'title': 'التقويم الهجري وأطوار القمر',
        'text': 'تقويم هجري دقيق يعرض الأيام البيض، والمناسبات الدينية المباركة، ومتابعة تفاعلية لأطوار القمر مع محول تواريخ سريع بين الهجري والميلادي.',
        'cuts': [(239.5, 252.6)]
    },
    {
        'id': '06_tasbeeh',
        'title': 'السبحة الإلكترونية والتسبيح',
        'text': 'سبحة إلكترونية ذكية تتيح لك اختيار أورادك المفضلة، مع عداد تفاعلي سلس واهتزاز هادئ عند كل تسبيحة، مع حفظ تلقائي لمجموع أذكارك.',
        'cuts': [(256.0, 261.0), (266.0, 274.4)]
    },
    {
        'id': '07_azkar',
        'title': 'حصن المسلم والأذكار',
        'text': 'حصن المسلم متكامل بأذكار الصباح والمساء واليوم والليلة، مزودة بعدادات تنازلية تفاعلية تتغير عند إتمام القراءة مع بيان فضل كل ذكر وسنده.',
        'cuts': [(283.0, 296.3)]
    },
    {
        'id': '08_allah_names',
        'title': 'أسماء الله الحسنى',
        'text': 'أسماء الله الحسنى التسعة والتسعون بتصميم بديع، مع شرح معانيها الإيمانية، والشواهد من القرآن الكريم، وخاصية التسبيح والذكر بكل اسم جليل.',
        'cuts': [(307.0, 319.6)]
    },
    {
        'id': '09_fiqh',
        'title': 'الفقه الإسلامي الميسر',
        'text': 'الفقه الإسلامي الميسر يقدم أحكام العبادات من طهارة وصلاة وصيام بأسلوب مبسط وموثق بالأدلة لتيسير معرفة أحكام الدين في شتى شؤون الحياة.',
        'cuts': [(333.0, 345.5)]
    },
    {
        'id': '10_qibla',
        'title': 'القبلة وطريقة الشمس',
        'text': 'تحديد فائق الدقة لاتجاه القبلة عبر البوصلة الحية، أو بطريقة الشمس المبتكرة التي تعمل بدون إنترنت وبدون الحاجة لمستشعر البوصلة.',
        'cuts': [(358.0, 369.1)]
    },
    {
        'id': '11_fonts',
        'title': 'تخصيص الخط والمظهر',
        'text': 'خيارات تخصيص مرنة تتيح لك التحكم بحجم خط الشاشة الرئيسية ونصوص المصحف لتوفير أقصى درجات الراحة البصرية وسهولة القراءة للجميع.',
        'cuts': [(388.5, 400.2)]
    },
    {
        'id': '12_outro',
        'title': 'الوضع الليلي والخاتمة',
        'text': 'مع دعم كامل للوضع الليلي الأنيق والمريح للعينين. تطبيق الهُدى، زادك اليومي إلى الطاعة والسكينة. نسأل الله أن يتقبل منا ومنكم صالح الأعمال.',
        'cuts': [(403.0, 417.0)]
    }
]

def get_duration(file_path):
    cmd = ['ffprobe', '-v', 'quiet', '-show_entries', 'format=duration', '-of', 'json', file_path]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return float(json.loads(res.stdout)['format']['duration'])

async def step1_generate_audio():
    print('=== Step 1: Generating Audio with Hamed Saudi Voice (ar-SA-HamedNeural) ===')
    for sec in SECTIONS:
        audio_file = f"{TEMP_DIR}/audio/{sec['id']}.mp3"
        if not os.path.exists(audio_file) or os.path.getsize(audio_file) < 1000:
            print(f"Generating audio for {sec['id']}...")
            tts = edge_tts.Communicate(sec['text'], VOICE, rate='+0%')
            await tts.save(audio_file)
        dur = get_duration(audio_file)
        sec['audio_dur'] = dur
        print(f"  {sec['id']}: {dur:.2f}s")

def step2_extract_and_assemble_clips():
    print('\n=== Step 2: Extracting and Assembling Video Clips ===')
    for sec in SECTIONS:
        sec_id = sec['id']
        audio_file = f"{TEMP_DIR}/audio/{sec_id}.mp3"
        audio_dur = sec['audio_dur']
        cuts = sec['cuts']
        
        # If multiple cuts, extract subclips and concat
        subclip_files = []
        for idx, (start, end) in enumerate(cuts):
            sub_path = f"{TEMP_DIR}/raw_clips/{sec_id}_part{idx}.mp4"
            cmd = [
                'ffmpeg', '-y',
                '-ss', str(start), '-to', str(end),
                '-i', RAW_VIDEO,
                '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '18',
                '-an', sub_path
            ]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            subclip_files.append(sub_path)
            
        combined_raw = f"{TEMP_DIR}/raw_clips/{sec_id}_raw.mp4"
        if len(subclip_files) == 1:
            shutil.copy2(subclip_files[0], combined_raw)
        else:
            list_txt = f"{TEMP_DIR}/raw_clips/{sec_id}_list.txt"
            with open(list_txt, 'w', encoding='utf-8') as f:
                for sf in subclip_files:
                    safe = sf.replace('\\', '/')
                    f.write(f"file '{safe}'\n")
            cmd = [
                'ffmpeg', '-y',
                '-f', 'concat', '-safe', '0',
                '-i', list_txt,
                '-c', 'copy',
                combined_raw
            ]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        # Conform to uniform resolution (720x1280), fps=30, match exact audio duration, merge audio
        out_uniform = f"{TEMP_DIR}/uniform_clips/{sec_id}.mp4"
        raw_dur = get_duration(combined_raw)
        speed_factor = raw_dur / audio_dur
        
        print(f"Processing {sec_id}: raw={raw_dur:.2f}s, audio={audio_dur:.2f}s (speed ratio: {speed_factor:.2f})")
        
        vf = f"setpts={1.0 / speed_factor:.4f}*PTS,fps=30,scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,format=yuv420p"
        
        cmd = [
            'ffmpeg', '-y',
            '-i', combined_raw,
            '-i', audio_file,
            '-vf', vf,
            '-map', '0:v:0',
            '-map', '1:a:0',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '22',
            '-c:a', 'aac', '-b:a', '128k', '-ar', '44100',
            '-t', str(audio_dur),
            out_uniform
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"  -> Generated {out_uniform} ({get_duration(out_uniform):.2f}s)")

def step3_concatenate_master():
    print('\n=== Step 3: Concatenating Master Video ===')
    concat_list = f"{TEMP_DIR}/master_concat.txt"
    with open(concat_list, 'w', encoding='utf-8') as f:
        for sec in SECTIONS:
            fpath = f"{TEMP_DIR}/uniform_clips/{sec['id']}.mp4".replace('\\', '/')
            f.write(f"file '{fpath}'\n")

    master_temp = f"{TEMP_DIR}/app_guide_master.mp4"
    cmd = [
        'ffmpeg', '-y',
        '-f', 'concat', '-safe', '0',
        '-i', concat_list,
        '-c:v', 'libx264', '-preset', 'medium', '-crf', '23',
        '-c:a', 'aac', '-b:a', '128k',
        '-movflags', '+faststart',
        master_temp
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    master_dur = get_duration(master_temp)
    master_size_mb = os.path.getsize(master_temp) / (1024 * 1024)
    print(f"\n Master Video Created: {master_temp}")
    print(f" Duration: {master_dur:.1f}s ({master_dur/60:.2f} min)")
    print(f" Size: {master_size_mb:.2f} MB (Reduced from 183 MB!)")

    # Step 4: Replace old video in assets
    print(f"\n=== Step 4: Replacing old video at {FINAL_TARGET} ===")
    shutil.copy2(master_temp, FINAL_TARGET)
    print(f" Successfully replaced {FINAL_TARGET}!")

async def main():
    await step1_generate_audio()
    step2_extract_and_assemble_clips()
    step3_concatenate_master()

if __name__ == '__main__':
    asyncio.run(main())
