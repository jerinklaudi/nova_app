"""
Generate YOLOv8n TFLite model compatible with flutter_vision

Requirements:
pip install ultralytics

Usage:
python generate_yolo_model.py
"""

from ultralytics import YOLO
import os

print("🔧 Loading/Downloading YOLOv8n model...")
model = YOLO('yolov8n.pt')  # Auto-downloads if not present

print("📦 Exporting to TensorFlow Lite format for flutter_vision...")
success = model.export(
    format='tflite',
    imgsz=640,          # 640x640 input size
    int8=False,         # No quantization
)

print(f"\n✅ Done! Model exported to: {success}")
print(f"\n📁 Next steps:")
print(f"1. Copy the generated .tflite file to:")
print(f"   {os.path.abspath('assets/models/yolov8n.tflite')}")
print(f"2. Restart your Flutter app")
print(f"3. Test object detection!")

