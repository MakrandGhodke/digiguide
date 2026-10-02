import os
import sys
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable, Preformatted
)
from reportlab.pdfgen import canvas

# Define NumberedCanvas for professional "Page X of Y" and running headers
class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))

        # Running Header on page 2 and later
        if self._pageNumber > 1:
            self.drawString(54, 755, "DigiGuide : Project Analysis & Developer Guide")
            self.drawRightString(612 - 54, 755, "October 2026")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(54, 748, 612 - 54, 748)

        # Running Footer on all pages
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 45, 612 - 54, 45)

        self.drawString(54, 32, "Confidential & Proprietary | Prepared for Makrand Ghodke")
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(612 - 54, 32, page_text)
        self.restoreState()


def create_pdf(filename="DigiGuide_Project_Analysis_and_Developer_Guide.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Custom Color Palette
    PRIMARY = colors.HexColor("#0F172A")     # Slate 900
    ACCENT_BLUE = colors.HexColor("#2563EB") # Blue 600
    TEXT_DARK = colors.HexColor("#1E293B")   # Slate 800
    TEXT_MUTED = colors.HexColor("#64748B")  # Slate 500
    BG_LIGHT = colors.HexColor("#F8FAFC")    # Slate 50
    CARD_BORDER = colors.HexColor("#CBD5E1") # Slate 300
    WARN_BG = colors.HexColor("#FEF3C7")     # Amber 100
    WARN_BORDER = colors.HexColor("#D97706") # Amber 600
    CODE_BG = colors.HexColor("#F1F5F9")     # Slate 100

    # Custom Typography Styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=PRIMARY,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=ACCENT_BLUE,
        spaceAfter=12
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=PRIMARY,
        spaceBefore=10,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=ACCENT_BLUE,
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'DocBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13.5,
        textColor=TEXT_DARK,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'DocBullet',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=TEXT_DARK,
        leftIndent=14,
        firstLineIndent=-10,
        spaceAfter=4
    )

    code_block_style = ParagraphStyle(
        'DocCodeBlock',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=7.5,
        leading=10.5,
        textColor=colors.HexColor("#0F172A")
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=colors.HexColor("#78350F")
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=TEXT_DARK
    )

    table_cell_bold = ParagraphStyle(
        'TableCellBold',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=11,
        textColor=PRIMARY
    )

    story = []

    # =========================================================================
    # PAGE 1: COVER & EXECUTIVE SUMMARY
    # =========================================================================
    story.append(Paragraph("DigiGuide : Project Analysis & Developer Guide", title_style))
    story.append(Paragraph("AI-Powered Smart Landmark Recognition & Audio Companion | Architecture & Technical Manual", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=ACCENT_BLUE, spaceBefore=0, spaceAfter=10))

    # Meta Info Card Table
    meta_data = [
        [
            Paragraph("<b>Repository:</b> MakrandGhodke/digiguide", table_cell_style),
            Paragraph("<b>Maintainer:</b> Makrand Ghodke", table_cell_style),
            Paragraph("<b>Date:</b> October 2026", table_cell_style)
        ],
        [
            Paragraph("<b>Location Focus:</b> Darmstadt, Germany", table_cell_style),
            Paragraph("<b>Tech Stack:</b> Flutter + FastAPI + CLIP + FAISS", table_cell_style),
            Paragraph("<b>Status:</b> Active Development", table_cell_style)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[175, 175, 154])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('BOX', (0,0), (-1,-1), 1, CARD_BORDER),
        ('INNERGRID', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    story.append(Paragraph("1. Executive Summary & Core Mission", h1_style))
    story.append(Paragraph(
        "<b>DigiGuide</b> is an intelligent, camera-first mobile tourist companion application designed to bring historical "
        "landmarks to life through real-time artificial intelligence. Designed specifically for the city of <b>Darmstadt, Germany</b>, "
        "DigiGuide empowers tourists and visitors to simply point their smartphone camera at any historic monument or architectural "
        "site and immediately unlock rich cultural insights, verified fun facts, and hands-free spoken audio guides.",
        body_style
    ))
    story.append(Paragraph(
        "Rather than relying on basic image classification or cloud reverse image search, DigiGuide utilizes an end-to-end "
        "<b>multimodal AI pipeline</b>: input photos are transformed into dense semantic embeddings using <b>OpenAI's CLIP</b> "
        "(Contrastive Language-Image Pretraining), queried against a high-speed <b>FAISS vector database</b> with multi-angle rotation "
        "invariance, and cross-validated against <b>real-time GPS geofencing</b>.",
        body_style
    ))

    story.append(Paragraph("<b>Key User Experience Capabilities:</b>", body_style))
    story.append(Paragraph("&bull; <b>Instant Camera Recognition:</b> Sub-second identification of monuments even under varied lighting, angles, and camera orientations.", bullet_style))
    story.append(Paragraph("&bull; <b>Curated Cultural Narratives:</b> Comprehensive historical dossiers, architectural background, and verified fun facts for each landmark.", bullet_style))
    story.append(Paragraph("&bull; <b>Proximity Audio Tours:</b> An automated hands-free guide mode that detects when visitors walk within 100 meters of a landmark and speaks natural narration via Text-to-Speech.", bullet_style))
    story.append(Paragraph("&bull; <b>Live Weather Intelligence:</b> Seamlessly pulls live temperature and outdoor visiting recommendations using Open-Meteo.", bullet_style))
    story.append(Paragraph("&bull; <b>Exploration & Personal History:</b> Categorized landmark discovery (Urban, History, Nature), bookmarking, and local scan history tracking.", bullet_style))
    story.append(Spacer(1, 14))

    # Architecture Overview Callout
    summary_box_data = [[
        Paragraph(
            "<b>Architectural Principle:</b> Clean decoupling between the cross-platform mobile client (Flutter) and "
            "the AI inference engine (FastAPI). The backend acts as a high-throughput stateless inference server, while "
            "the mobile app handles sensor orchestration (Camera, GPS, TTS) and offline caching for optimal battery and data efficiency.",
            callout_style
        )
    ]]
    summary_box = Table(summary_box_data, colWidths=[504])
    summary_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('BOX', (0,0), (-1,-1), 1, CARD_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(summary_box)

    # =========================================================================
    # PAGE 2: SYSTEM PIPELINE & TECHNOLOGY STACK
    # =========================================================================
    story.append(PageBreak())

    story.append(Paragraph("2. System Workflow & Data Pipeline", h1_style))
    story.append(Paragraph(
        "When a user captures a photograph in the mobile app, the system executes an optimized 7-stage recognition pipeline:",
        body_style
    ))

    workflow_data = [
        [Paragraph("Step", table_header_style), Paragraph("Component", table_header_style), Paragraph("Action & Processing Details", table_header_style)],
        [
            Paragraph("<b>1. Capture</b>", table_cell_bold),
            Paragraph("Flutter Client", table_cell_style),
            Paragraph("User captures image via live viewfinder or gallery. Geolocator simultaneously queries current GPS coordinates (lat, lon).", table_cell_style)
        ],
        [
            Paragraph("<b>2. Transport</b>", table_cell_bold),
            Paragraph("REST API", table_cell_style),
            Paragraph("Client sends multipart/form-data request to <code>POST /predict</code> containing image bytes and optional latitude/longitude.", table_cell_style)
        ],
        [
            Paragraph("<b>3. Rotation Fix</b>", table_cell_bold),
            Paragraph("Pillow Engine", table_cell_style),
            Paragraph("Applies <code>ImageOps.exif_transpose()</code> to correct phone sensor orientation, and evaluates 4 angles (0°, 90°, 180°, 270°) to prevent rotated photo failures.", table_cell_style)
        ],
        [
            Paragraph("<b>4. Embedding</b>", table_cell_bold),
            Paragraph("OpenAI CLIP", table_cell_style),
            Paragraph("Extracts visual semantics into an L2-normalized 512-dimensional vector using <code>openai/clip-vit-base-patch32</code>.", table_cell_style)
        ],
        [
            Paragraph("<b>5. Vector Search</b>", table_cell_bold),
            Paragraph("FAISS Index", table_cell_style),
            Paragraph("Queries <code>IndexFlatL2</code> for top-k nearest neighbors. L2 Euclidean distance is converted into cosine similarity: <i>sim = max(0, 1 - d²/2)</i>.", table_cell_style)
        ],
        [
            Paragraph("<b>6. Validation</b>", table_cell_bold),
            Paragraph("Geofencing", table_cell_style),
            Paragraph("If similarity &ge; 0.85, visual match is confirmed. If below threshold and GPS is provided, Haversine formula ranks closest landmarks within 50km as suggestions.", table_cell_style)
        ],
        [
            Paragraph("<b>7. Narration</b>", table_cell_bold),
            Paragraph("Flutter TTS", table_cell_style),
            Paragraph("Client displays full historical narrative, bullet points, weather, and plays natural 0.5x speed audio narration.", table_cell_style)
        ]
    ]

    workflow_table = Table(workflow_data, colWidths=[65, 95, 344])
    workflow_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(workflow_table)
    story.append(Spacer(1, 10))

    story.append(Paragraph("3. Technology Stack Breakdown", h1_style))

    tech_data = [
        [Paragraph("Layer", table_header_style), Paragraph("Technology", table_header_style), Paragraph("Role / Implementation Purpose", table_header_style)],
        [
            Paragraph("<b>Mobile UI</b>", table_cell_bold),
            Paragraph("Flutter 3.x / Dart", table_cell_style),
            Paragraph("Cross-platform mobile client with custom Material 3 light/dark responsive themes.", table_cell_style)
        ],
        [
            Paragraph("<b>State Mgmt</b>", table_cell_bold),
            Paragraph("Provider 6.0", table_cell_style),
            Paragraph("ChangeNotifier providers for Favorites, ThemeMode, and background AudioTourService.", table_cell_style)
        ],
        [
            Paragraph("<b>Audio / Speech</b>", table_cell_bold),
            Paragraph("flutter_tts", table_cell_style),
            Paragraph("Text-to-speech engine delivering clear historical narratives and walking tours.", table_cell_style)
        ],
        [
            Paragraph("<b>Sensors / GPS</b>", table_cell_bold),
            Paragraph("geolocator & camera", table_cell_style),
            Paragraph("Live camera viewfinder access and continuous GPS stream tracking with 10-meter distance filtering.", table_cell_style)
        ],
        [
            Paragraph("<b>Backend API</b>", table_cell_bold),
            Paragraph("FastAPI & Uvicorn", table_cell_style),
            Paragraph("Asynchronous ASGI web service supporting multipart uploads and JSON endpoints.", table_cell_style)
        ],
        [
            Paragraph("<b>Vision Model</b>", table_cell_bold),
            Paragraph("CLIP (HuggingFace)", table_cell_style),
            Paragraph("Pretrained <code>clip-vit-base-patch32</code> PyTorch model generating 512-dim visual embeddings.", table_cell_style)
        ],
        [
            Paragraph("<b>Vector Index</b>", table_cell_bold),
            Paragraph("FAISS (faiss-cpu)", table_cell_style),
            Paragraph("High-performance nearest neighbor vector search engine supporting exact Euclidean distance matching.", table_cell_style)
        ],
        [
            Paragraph("<b>Authentication</b>", table_cell_bold),
            Paragraph("bcrypt & python-jose", table_cell_style),
            Paragraph("Salted SHA-256 password hashing and JWT token issuance for 30-day mobile sessions.", table_cell_style)
        ],
        [
            Paragraph("<b>Weather API</b>", table_cell_bold),
            Paragraph("Open-Meteo REST", table_cell_style),
            Paragraph("Public weather forecast API mapping WMO weather codes to temperature, icons, and conditions.", table_cell_style)
        ]
    ]

    tech_table = Table(tech_data, colWidths=[90, 110, 304])
    tech_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(tech_table)

    # =========================================================================
    # PAGE 3: REPOSITORY STRUCTURE & CURRENT LANDMARKS
    # =========================================================================
    story.append(PageBreak())

    story.append(Paragraph("4. Repository Structure & Key Components", h1_style))
    story.append(Paragraph("The project codebase is organized into modular services and data stores:", body_style))

    file_data = [
        [Paragraph("File / Directory", table_header_style), Paragraph("Component", table_header_style), Paragraph("Responsibility & Key Functions", table_header_style)],
        [
            Paragraph("<code>main.py</code>", table_cell_bold),
            Paragraph("FastAPI Server", table_cell_style),
            Paragraph("Entry point for backend server; registers endpoints (<code>/predict</code>, <code>/landmarks</code>, <code>/nearby</code>, <code>/weather</code>, <code>/auth</code>) and contains landmark dossiers.", table_cell_style)
        ],
        [
            Paragraph("<code>utils.py</code>", table_cell_bold),
            Paragraph("Model Pipeline", table_cell_style),
            Paragraph("Loads CLIP model to GPU/CPU; provides <code>image_to_embedding()</code> with L2 normalization.", table_cell_style)
        ],
        [
            Paragraph("<code>build_index.py</code>", table_cell_bold),
            Paragraph("Indexer Script", table_cell_style),
            Paragraph("Scans <code>dataset/</code> photos, feeds them through CLIP, and outputs <code>vector_store.index</code> & <code>metadata.json</code>.", table_cell_style)
        ],
        [
            Paragraph("<code>locations.json</code>", table_cell_bold),
            Paragraph("Geo Data", table_cell_style),
            Paragraph("Accurate latitude and longitude coordinates for all indexed Darmstadt landmarks.", table_cell_style)
        ],
        [
            Paragraph("<code>metadata.json</code>", table_cell_bold),
            Paragraph("Vector Mapping", table_cell_style),
            Paragraph("Maps FAISS numeric index IDs to landmark names, filenames, and GPS coordinates.", table_cell_style)
        ],
        [
            Paragraph("<code>update_ip.py</code>", table_cell_bold),
            Paragraph("Dev Utility", table_cell_style),
            Paragraph("Detects host machine IP and updates <code>frontend/lib/config.dart</code> for USB reverse tunneling or Wi-Fi.", table_cell_style)
        ],
        [
            Paragraph("<code>dataset/</code>", table_cell_bold),
            Paragraph("Image Dataset", table_cell_style),
            Paragraph("Reference photographic dataset organized into 11 landmark class folders.", table_cell_style)
        ],
        [
            Paragraph("<code>frontend/lib/</code>", table_cell_bold),
            Paragraph("Flutter Source", table_cell_style),
            Paragraph("Application entry (<code>main.dart</code>), screens (Home, Camera, Explore, Result, Profile), and services.", table_cell_style)
        ]
    ]

    file_table = Table(file_data, colWidths=[110, 85, 309])
    file_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(file_table)
    story.append(Spacer(1, 10))

    story.append(Paragraph("5. Current Landmark Coverage (11 Darmstadt Sites)", h1_style))
    story.append(Paragraph("The visual vector store and knowledge base currently index 11 major sites across Darmstadt:", body_style))

    landmarks_data = [
        [Paragraph("Landmark Slug", table_header_style), Paragraph("Official Name", table_header_style), Paragraph("Category", table_header_style), Paragraph("Coordinates", table_header_style)],
        [Paragraph("<code>darmstadium</code>", table_cell_style), Paragraph("Darmstadtium Congress Center", table_cell_bold), Paragraph("Urban / Modern", table_cell_style), Paragraph("49.8732° N, 8.6558° E", table_cell_style)],
        [Paragraph("<code>mathildenhöhe</code>", table_cell_style), Paragraph("Mathildenhöhe (UNESCO Site)", table_cell_bold), Paragraph("History / Art", table_cell_style), Paragraph("49.8775° N, 8.6675° E", table_cell_style)],
        [Paragraph("<code>schloss</code>", table_cell_style), Paragraph("Residenzschloss Darmstadt", table_cell_bold), Paragraph("History / Palace", table_cell_style), Paragraph("49.8728° N, 8.6552° E", table_cell_style)],
        [Paragraph("<code>waldspirale</code>", table_cell_style), Paragraph("Waldspirale (Hundertwasser)", table_cell_bold), Paragraph("Architecture", table_cell_style), Paragraph("49.8863° N, 8.6554° E", table_cell_style)],
        [Paragraph("<code>Luisenplatz</code>", table_cell_style), Paragraph("Luisenplatz & Ludwigsmonument", table_cell_bold), Paragraph("Urban / Center", table_cell_style), Paragraph("49.8724° N, 8.6511° E", table_cell_style)],
        [Paragraph("<code>Hessisches-Landesmuseum</code>", table_cell_style), Paragraph("Hessian State Museum", table_cell_bold), Paragraph("Culture / Museum", table_cell_style), Paragraph("49.8745° N, 8.6548° E", table_cell_style)],
        [Paragraph("<code>Staatstheater</code>", table_cell_style), Paragraph("Staatstheater Darmstadt", table_cell_bold), Paragraph("Culture / Theater", table_cell_style), Paragraph("49.8688° N, 8.6516° E", table_cell_style)],
        [Paragraph("<code>herrengarten</code>", table_cell_style), Paragraph("Herrngarten (Central Park)", table_cell_bold), Paragraph("Nature / Park", table_cell_style), Paragraph("49.8760° N, 8.6530° E", table_cell_style)],
        [Paragraph("<code>orangerie_park</code>", table_cell_style), Paragraph("Orangerie Baroque Garden", table_cell_bold), Paragraph("Nature / Baroque", table_cell_style), Paragraph("49.8596° N, 8.6565° E", table_cell_style)],
        [Paragraph("<code>prinz-emil-garten</code>", table_cell_style), Paragraph("Prinz-Emil-Garten", table_cell_bold), Paragraph("Nature / Park", table_cell_style), Paragraph("49.8580° N, 8.6480° E", table_cell_style)],
        [Paragraph("<code>jugendstilbad</code>", table_cell_style), Paragraph("Jugendstilbad (Art Nouveau Spa)", table_cell_bold), Paragraph("History / Wellness", table_cell_style), Paragraph("49.8727° N, 8.6601° E", table_cell_style)]
    ]

    lm_table = Table(landmarks_data, colWidths=[120, 164, 100, 120])
    lm_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(lm_table)

    # =========================================================================
    # PAGE 4: CRITICAL CODEBASE FINDINGS & DEFECTS
    # =========================================================================
    story.append(PageBreak())

    story.append(Paragraph("6. Critical Codebase Findings & Defects to Address", h1_style))
    story.append(Paragraph(
        "A rigorous forensic review of the repository revealed 4 architectural bugs and technical debt items:",
        body_style
    ))

    # Issue 1
    issue1_data = [[
        Paragraph(
            "<b>Defect 1: Duplicate & Shadowed Endpoints in <code>main.py</code></b><br/>"
            "Lines 917 to 1361 are an unmerged duplicate of lines 347 to 881 resulting from a prior Git merge conflict. "
            "In FastAPI/Starlette, routes are evaluated in first-registered order. As a result, the newer bug fixes placed at the bottom "
            "(specifically the updated Open-Meteo API query format) are never reached, and the older handler intercepts traffic first.<br/>"
            "<b>Remediation:</b> Delete the duplicate bottom block (lines 917–1361) and port over any newer query fixes to the top handlers.",
            callout_style
        )
    ]]
    issue1_box = Table(issue1_data, colWidths=[504])
    issue1_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), WARN_BG),
        ('BOX', (0,0), (-1,-1), 1, WARN_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(issue1_box)
    story.append(Spacer(1, 8))

    # Issue 2
    issue2_data = [[
        Paragraph(
            "<b>Defect 2: Missing <code>POST /feedback</code> Endpoint on Backend</b><br/>"
            "In <code>landmark_result_screen.dart</code>, the mobile client issues a POST request to <code>/feedback</code> whenever a user "
            "submits a thumbs up/down accuracy rating. While the database table <code>reviews</code> exists in <code>users.db</code> and "
            "an export script (<code>export_reviews.py</code>) expects it, the actual endpoint was never created in <code>main.py</code>, "
            "causing mobile review submissions to throw 404 Not Found.<br/>"
            "<b>Remediation:</b> Implement <code>@app.post('/feedback')</code> to insert feedback records into SQLite.",
            callout_style
        )
    ]]
    issue2_box = Table(issue2_data, colWidths=[504])
    issue2_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), WARN_BG),
        ('BOX', (0,0), (-1,-1), 1, WARN_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(issue2_box)
    story.append(Spacer(1, 8))

    # Issue 3
    issue3_data = [[
        Paragraph(
            "<b>Defect 3: Split User Database Architecture</b><br/>"
            "Authentication endpoints in <code>main.py</code> read and write user credentials to a flat JSON file (<code>users.json</code>). "
            "Concurrently, a relational SQLite database (<code>users.db</code>) with <code>users</code> and <code>reviews</code> schemas "
            "exists alongside it. Plaintext JSON storage lacks ACID guarantees and concurrent write locking.<br/>"
            "<b>Remediation:</b> Migrate authentication storage from <code>users.json</code> into <code>users.db</code> using standard SQLite queries.",
            callout_style
        )
    ]]
    issue3_box = Table(issue3_data, colWidths=[504])
    issue3_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), WARN_BG),
        ('BOX', (0,0), (-1,-1), 1, WARN_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(issue3_box)
    story.append(Spacer(1, 8))

    # Issue 4
    issue4_data = [[
        Paragraph(
            "<b>Defect 4: Non-Persistent Favorites in Flutter</b><br/>"
            "In <code>frontend/lib/providers/favorites_provider.dart</code>, favorites are stored in a volatile Dart list "
            "(<code>final List&lt;Landmark&gt; _favorites = []</code>) without local serialization. When the mobile app is terminated, "
            "all user bookmarks are lost. Unlike <code>RecentHistoryService</code> which persists to <code>SharedPreferences</code>, "
            "favorites need persistence.<br/>"
            "<b>Remediation:</b> Implement JSON serialization and disk storage in <code>FavoritesProvider</code> via SharedPreferences.",
            callout_style
        )
    ]]
    issue4_box = Table(issue4_data, colWidths=[504])
    issue4_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), WARN_BG),
        ('BOX', (0,0), (-1,-1), 1, WARN_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(issue4_box)

    # =========================================================================
    # PAGE 5: DEVELOPER SETUP & ROADMAP
    # =========================================================================
    story.append(PageBreak())

    story.append(Paragraph("7. Developer Setup & Execution Guide", h1_style))
    story.append(Paragraph("Follow this sequential guide to run both the backend inference service and mobile app:", body_style))

    story.append(Paragraph("<b>Step 1: Backend Setup & Launch</b>", h2_style))
    step1_code = (
        "# 1. Create and activate Python virtual environment\n"
        "python -m venv .venv\n"
        ".\\.venv\\Scripts\\activate\n\n"
        "# 2. Install PyTorch, Transformers, FAISS, and FastAPI\n"
        "pip install -r requirements.txt\n\n"
        "# 3. Run FastAPI backend server with hot-reload\n"
        "uvicorn main:app --reload --host 0.0.0.0 --port 8000"
    )
    story.append(Table([[Preformatted(step1_code, code_block_style)]], colWidths=[504], style=[
        ('BACKGROUND', (0,0), (-1,-1), CODE_BG),
        ('BOX', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))

    story.append(Paragraph("<b>Step 2: Network Bridging (Mobile Connection)</b>", h2_style))
    step2_code = (
        "# Option A: Connected via USB Cable (Fast & Reliable)\n"
        "python update_ip.py --localhost\n"
        "adb reverse tcp:8000 tcp:8000\n\n"
        "# Option B: Wireless Mode (Phone and PC on same Wi-Fi)\n"
        "python update_ip.py"
    )
    story.append(Table([[Preformatted(step2_code, code_block_style)]], colWidths=[504], style=[
        ('BACKGROUND', (0,0), (-1,-1), CODE_BG),
        ('BOX', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))

    story.append(Paragraph("<b>Step 3: Run Mobile Application</b>", h2_style))
    step3_code = (
        "cd frontend\n"
        "flutter pub get\n"
        "flutter run"
    )
    story.append(Table([[Preformatted(step3_code, code_block_style)]], colWidths=[504], style=[
        ('BACKGROUND', (0,0), (-1,-1), CODE_BG),
        ('BOX', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(Spacer(1, 10))

    story.append(Paragraph("8. Prioritized Development Roadmap", h1_style))

    roadmap_data = [
        [Paragraph("Phase", table_header_style), Paragraph("Milestone Target", table_header_style), Paragraph("Key Deliverables & Action Items", table_header_style)],
        [
            Paragraph("<b>Phase 1</b><br/>Stability & Fixes", table_cell_bold),
            Paragraph("Codebase Deduplication & Storage", table_cell_style),
            Paragraph(
                "&bull; Remove duplicate routes (lines 917–1361) in <code>main.py</code>.<br/>"
                "&bull; Add <code>POST /feedback</code> endpoint saving ratings into SQLite.<br/>"
                "&bull; Unify auth storage into SQLite database.<br/>"
                "&bull; Persist user favorites to <code>SharedPreferences</code>.",
                table_cell_style
            )
        ],
        [
            Paragraph("<b>Phase 2</b><br/>Enhanced UX", table_cell_bold),
            Paragraph("Maps & Multilingual Tour", table_cell_style),
            Paragraph(
                "&bull; Interactive Map view (Mapbox / Google Maps) with pins.<br/>"
                "&bull; German / English bilingual audio guide toggle.<br/>"
                "&bull; Offline caching for offline tourists without data roaming.",
                table_cell_style
            )
        ],
        [
            Paragraph("<b>Phase 3</b><br/>AI & Scale", table_cell_bold),
            Paragraph("Model Calibration & Cities", table_cell_style),
            Paragraph(
                "&bull; Calibrate threshold with hybrid visual + GPS scoring.<br/>"
                "&bull; Expand dataset to Frankfurt, Heidelberg, and Rhine-Neckar.<br/>"
                "&bull; Curator web dashboard to upload new landmarks.",
                table_cell_style
            )
        ]
    ]

    roadmap_table = Table(roadmap_data, colWidths=[85, 115, 304])
    roadmap_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 4.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, CARD_BORDER),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(roadmap_table)

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated clean PDF: {filename}")


if __name__ == "__main__":
    create_pdf()
