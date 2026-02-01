# 🧠 DataTricks AI

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Backend-Python-3776AB?logo=python)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Active_Development-orange)]()

**DataTricks AI** is a next-generation DataOps platform designed to streamline the lifecycle of AI model development. Built with **Flutter Web** for high-performance rendering and **Python** for backend intelligence, it bridges the gap between raw data and production-ready models.

## 🚀 Key Features

### 🎨 Advanced Annotation Studio
- **2D Image Labeling:** Bounding boxes, polygons, and segmentation masks with sub-pixel precision.
- **3D LiDAR Support:** Native rendering of `.pcd` and `.ply` point clouds with 3D cuboid annotation tools.
- **AI-Assisted Labeling:** "Magic Select" tools powered by SAM (Segment Anything Model) and YOLOv8 to speed up manual work by 10x.

### 📊 LIDA Smart Insights
- **Automated Visualization:** Instantly generate histograms and scatter plots to understand class balance.
- **Bias Detection:** Identify underrepresented classes before training begins.

### 🤖 AutoML Pipeline
- **No-Code Training:** Train object detection models directly from the browser.
- **Real-time Monitoring:** Watch training loss and accuracy metrics in a terminal-like UI.

## 🛠️ Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter Web | Core UI, Canvas rendering, and State Management. |
| **3D Engine** | Three.js / Deck.gl | Integrated via `HtmlElementView` for high-performance point cloud rendering. |
| **Backend** | FastAPI / Django | Handles model inference, auth, and database orchestration. |
| **AI Models** | PyTorch / YOLO / SAM | Powering the auto-labeling and training features. |
| **Database** | PostgreSQL | Stores project metadata and annotation coordinates. |

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Python 3.9+
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone [https://github.com/kiokomuinde/datatricksai.git](https://github.com/kiokomuinde/datatricksai.git)
   cd datatricksai