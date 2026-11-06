# -*- coding: utf-8 -*-
"""
Re-concat using -c copy but force re-encode to fix duration mismatch.
Each merged clip is already correct (21s, 18s, etc.) so we just concat them properly.
"""
import subprocess, json, os, glob

ROOT = r'd:/Flutter Projects/alhuda/video_production'

def get_dur(path):
    cmd = ['ffprobe', '-v', 'quiet', '-show_entries', 'format=duration', '-of', 'json', path]
    r = subprocess.run(cmd, capture_output=True, text=True)
    return float(json.loads(r.stdout)['format']['duration'])

merged_files = sorted(glob.glob(f'{ROOT}/merged/*.mp4'))
print(f'Found {len(merged_files)} merged clips:')
total = 0
for f in merged_files:
    d = get_dur(f)
    total += d
    print(f'  {os.path.basename(f)}: {d:.1f}s')
print(f'Expected total: {total:.1f}s = {total/60:.2f} min')

# Re-encode all clips to uniform fps=30, same resolution, then concat
print('\n=== Re-encoding clips to uniform format ===')
uniform_dir = f'{ROOT}/uniform'
os.makedirs(uniform_dir, exist_ok=True)

uniform_files = []
for f in merged_files:
    name = os.path.basename(f)
    out = f'{uniform_dir}/{name}'
    cmd = [
        'ffmpeg', '-y', '-i', f,
        '-vf', 'fps=30,scale=1080:2280:force_original_aspect_ratio=decrease,pad=1080:2280:(ow-iw)/2:(oh-ih)/2',
        '-c:v', 'libx264', '-preset', 'fast', '-crf', '22',
        '-c:a', 'aac', '-b:a', '128k', '-ar', '44100',
        '-pix_fmt', 'yuv420p',
        out
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode == 0:
        print(f'  OK: {name}')
        uniform_files.append(out)
    else:
        print(f'  ERROR: {r.stderr[-200:]}')

# Concat
print(f'\n=== Concatenating {len(uniform_files)} uniform clips ===')
concat_list = f'{ROOT}/concat_uniform.txt'
with open(concat_list, 'w', encoding='utf-8') as f:
    for uf in uniform_files:
        safe = uf.replace('\\', '/')
        f.write(f"file '{safe}'\n")

final_output = f'{ROOT}/alhuda_app_tour_final.mp4'
cmd = [
    'ffmpeg', '-y',
    '-f', 'concat', '-safe', '0',
    '-i', concat_list,
    '-c', 'copy',
    '-movflags', '+faststart',
    final_output
]
r = subprocess.run(cmd, capture_output=True, text=True)
if r.returncode == 0:
    dur = get_dur(final_output)
    size_mb = os.path.getsize(final_output.replace('/', os.sep)) / 1024 / 1024
    print(f'\n=== DONE ===')
    print(f'File    : {final_output}')
    print(f'Duration: {dur:.1f}s = {dur/60:.2f} min')
    print(f'Size    : {size_mb:.1f} MB')
else:
    print(f'Concat error:\n{r.stderr[-400:]}')
