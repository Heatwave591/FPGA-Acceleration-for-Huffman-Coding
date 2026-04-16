import sys, io, zipfile, re, os, shutil
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
from PIL import Image

EMU_PER_INCH = 914400
MAX_W = int(5.5 * EMU_PER_INCH)
MAX_H = int(3.5 * EMU_PER_INCH)
DPI   = 96

def img_emu(path):
    img = Image.open(path)
    w_px, h_px = img.size
    w_emu = int(w_px * EMU_PER_INCH / DPI)
    h_emu = int(h_px * EMU_PER_INCH / DPI)
    scale = min(MAX_W / w_emu, MAX_H / h_emu, 1.0)
    return int(w_emu * scale), int(h_emu * scale)

images = [
    ('screenshots/Highly_Sparse/Encoder_config_Phase.png',
     'Fig. 8. Highly sparse - encoder configuration phase (0-200 ns). enc_data_config = 10000 confirms 1-bit code for 0x00.'),
    ('screenshots/Highly_Sparse/Encoding_and_first_flush.png',
     'Fig. 9. Highly sparse - encoding and decoder output (5400-5900 ns). stream_valid pulses infrequent; avg code length 3.3 bits (2.41x compression).'),
    ('screenshots/Highly_Sparse/Decoder_output.png',
     'Fig. 10. Highly sparse - close-up decoder output (5650-5950 ns). symbol_out correctly reproduces input sequence.'),
    ('screenshots/Moderate_sparse/Encoder config phase.png',
     'Fig. 11. Moderate - encoder configuration phase (0-200 ns). enc_data_config = 30000 confirms 3-bit code for 0x00.'),
    ('screenshots/Moderate_sparse/Encoding and first flush.png',
     'Fig. 12. Moderate - encoding and decoder output (5400-5900 ns). stream_valid more frequent; avg code length 5.9 bits (1.35x compression).'),
    ('screenshots/Moderate_sparse/Decoder_output.png',
     'Fig. 13. Moderate - close-up decoder output (5600-5900 ns). Round-trip verified for moderate distribution.'),
    ('screenshots/Dense/Encoder config phase.png',
     'Fig. 14. Dense - encoder configuration phase (0-200 ns). enc_data_config = 50000 confirms 5-bit code for 0x00.'),
    ('screenshots/Dense/Encoding and first flush.png',
     'Fig. 15. Dense - encoding and decoder output (5400-5900 ns). stream_valid most frequent; avg code length 7.9 bits (1.02x compression).'),
    ('screenshots/Dense/Decoder output.png',
     'Fig. 16. Dense - close-up decoder output (5650-5950 ns). Round-trip verified for dense distribution.'),
]

# Re-unpack fresh
if os.path.exists('unpacked3'):
    shutil.rmtree('unpacked3')
with zipfile.ZipFile('Report.docx') as z:
    z.extractall('unpacked3')

media_dir = 'unpacked3/word/media'
next_img  = 8
next_rid  = 14

# Copy images into media
img_info = []
for path, caption in images:
    img_name = 'image{}.png'.format(next_img)
    rid      = 'rId{}'.format(next_rid)
    shutil.copy(path, os.path.join(media_dir, img_name))
    w, h = img_emu(path)
    img_info.append((rid, img_name, w, h, caption, next_img))
    next_img += 1
    next_rid += 1

print('Images copied: {}'.format(len(img_info)))

# Add relationships
with open('unpacked3/word/_rels/document.xml.rels', encoding='utf-8') as f:
    rels = f.read()

img_type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image'
new_rels = ''
for rid, img_name, w, h, cap, idx in img_info:
    new_rels += '<Relationship Id="{}" Type="{}" Target="media/{}"/>'.format(rid, img_type, img_name)

rels = rels.replace('</Relationships>', new_rels + '</Relationships>')
with open('unpacked3/word/_rels/document.xml.rels', 'w', encoding='utf-8') as f:
    f.write(rels)
print('Relationships written.')

# Build drawing XML
def make_drawing(rid, w, h, pic_id):
    ns_a   = 'http://schemas.openxmlformats.org/drawingml/2006/main'
    ns_pic = 'http://schemas.openxmlformats.org/drawingml/2006/picture'
    ns_r   = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
    return (
        '<w:drawing>'
        '<wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="{w}" cy="{h}"/>'
        '<wp:effectExtent l="0" t="0" r="0" b="0"/>'
        '<wp:docPr id="{pid}" name="Fig{pid}"/>'
        '<wp:cNvGraphicFramePr>'
        '<a:graphicFrameLocks xmlns:a="{ns_a}" noChangeAspect="1"/>'
        '</wp:cNvGraphicFramePr>'
        '<a:graphic xmlns:a="{ns_a}">'
        '<a:graphicData uri="{ns_pic}">'
        '<pic:pic xmlns:pic="{ns_pic}">'
        '<pic:nvPicPr>'
        '<pic:cNvPr id="{pid}" name="Fig{pid}"/>'
        '<pic:cNvPicPr/>'
        '</pic:nvPicPr>'
        '<pic:blipFill>'
        '<a:blip r:embed="{rid}" xmlns:r="{ns_r}"/>'
        '<a:stretch><a:fillRect/></a:stretch>'
        '</pic:blipFill>'
        '<pic:spPr>'
        '<a:xfrm><a:off x="0" y="0"/><a:ext cx="{w}" cy="{h}"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
        '</pic:spPr>'
        '</pic:pic>'
        '</a:graphicData>'
        '</a:graphic>'
        '</wp:inline>'
        '</w:drawing>'
    ).format(w=w, h=h, pid=pic_id, rid=rid, ns_a=ns_a, ns_pic=ns_pic, ns_r=ns_r)

def body_para(text):
    return (
        '<w:p><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/>'
        '<w:jc w:val="both"/></w:pPr>'
        '<w:r><w:t xml:space="preserve">{}</w:t></w:r></w:p>'
    ).format(text)

def subhead_para(text):
    return (
        '<w:p><w:pPr><w:spacing w:before="160" w:after="60"/></w:pPr>'
        '<w:r><w:rPr><w:b/><w:bCs/></w:rPr>'
        '<w:t>{}</w:t></w:r></w:p>'
    ).format(text)

def heading_para(text):
    return (
        '<w:p><w:pPr><w:spacing w:before="180" w:after="80"/></w:pPr>'
        '<w:r><w:rPr><w:b/><w:bCs/><w:i/><w:iCs/></w:rPr>'
        '<w:t>{}</w:t></w:r></w:p>'
    ).format(text)

def img_para(rid, w, h, pic_id, caption):
    return (
        '<w:p><w:pPr><w:spacing w:after="40"/><w:jc w:val="center"/></w:pPr>'
        '<w:r>{}</w:r></w:p>'
        '<w:p><w:pPr><w:spacing w:after="120"/><w:jc w:val="center"/></w:pPr>'
        '<w:r><w:rPr><w:i/><w:iCs/></w:rPr>'
        '<w:t xml:space="preserve">{}</w:t></w:r></w:p>'
    ).format(make_drawing(rid, w, h, pic_id), caption)

section_xml = heading_para('D. Gradient Distribution Simulation Results')
section_xml += body_para(
    'The following waveforms demonstrate hardware correctness across all three gradient '
    'distributions. For each scenario, three timestamps are shown: the encoder configuration '
    'phase (0-200 ns) confirming the correct codebook was loaded, the encoding and decoding '
    'window (5400-5900 ns) showing stream output and round-trip behaviour, and a close-up '
    'of the decoder output confirming symbol_out matches the original input sequence.'
)

section_xml += subhead_para('1) Highly Sparse  (FREQS[0x00] = 10,000  |  Compression Ratio: 2.41x)')
for i in range(3):
    rid, img_name, w, h, cap, idx = img_info[i]
    section_xml += img_para(rid, w, h, 100 + i, cap)

section_xml += subhead_para('2) Moderate  (FREQS[0x00] = 1,000  |  Compression Ratio: 1.35x)')
for i in range(3, 6):
    rid, img_name, w, h, cap, idx = img_info[i]
    section_xml += img_para(rid, w, h, 100 + i, cap)

section_xml += subhead_para('3) Dense  (FREQS[0x00] = 100  |  Compression Ratio: 1.02x)')
for i in range(6, 9):
    rid, img_name, w, h, cap, idx = img_info[i]
    section_xml += img_para(rid, w, h, 100 + i, cap)

# Insert before 'D. Correctness Summary'
with open('unpacked3/word/document.xml', encoding='utf-8') as f:
    doc = f.read()

target = 'D. Correctness Summary'
if target in doc:
    idx = doc.index(target)
    p_start = doc.rindex('<w:p', 0, idx)
    doc = doc[:p_start] + section_xml + doc[p_start:]
    print('Section inserted before D. Correctness Summary')
else:
    print('ERROR: target not found in document')

with open('unpacked3/word/document.xml', 'w', encoding='utf-8') as f:
    f.write(doc)

# Repack
with zipfile.ZipFile('Report.docx', 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk('unpacked3'):
        for file in files:
            abs_path = os.path.join(root, file)
            arc_path = os.path.relpath(abs_path, 'unpacked3')
            zf.write(abs_path, arc_path)

print('Done. Report.docx updated with 9 waveform screenshots.')
