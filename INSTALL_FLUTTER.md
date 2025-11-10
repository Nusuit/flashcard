# 🚀 Hướng dẫn cài đặt Flutter để chạy Knop

## Cách 1: Cài Flutter bằng Git (Khuyên dùng)

### Bước 1: Clone Flutter SDK

```bash
cd C:\
git clone https://github.com/flutter/flutter.git -b stable
```

### Bước 2: Thêm Flutter vào PATH

1. Mở **Settings** → Tìm "environment variables"
2. Click **Environment Variables**
3. Trong **System variables**, tìm **Path** và click **Edit**
4. Click **New** và thêm: `C:\flutter\bin`
5. Click **OK** để lưu

### Bước 3: Verify cài đặt

```bash
# Mở terminal mới
flutter doctor
```

### Bước 4: Cài Visual Studio (cho Windows desktop)

```bash
# Tải và cài Visual Studio 2022 Community
# Chọn "Desktop development with C++"
# Link: https://visualstudio.microsoft.com/downloads/
```

### Bước 5: Chạy Flutter Doctor

```bash
flutter doctor
```

---

## Cách 2: Cài Flutter bằng file ZIP (Nhanh hơn)

### Bước 1: Tải Flutter SDK

1. Vào: https://docs.flutter.dev/get-started/install/windows
2. Tải file ZIP (khoảng 1.5GB)
3. Giải nén vào `C:\flutter`

### Bước 2-5: Giống như Cách 1

---

## Sau khi cài xong Flutter

### Chạy ứng dụng Knop:

```bash
cd D:\Code\Important\project\knop_flashcard
flutter pub get
flutter run -d windows
```

### Hoặc build file .exe:

```bash
flutter build windows --release
# File .exe sẽ ở: build\windows\runner\Release\knop_flashcard.exe
```

---

## ⚡ Lệnh nhanh (Copy & paste)

```bash
# Cài Flutter
cd C:\
git clone https://github.com/flutter/flutter.git -b stable

# Thêm vào PATH (chạy PowerShell as Admin)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", "Machine")

# Verify
flutter doctor

# Chạy app
cd D:\Code\Important\project\knop_flashcard
flutter pub get
flutter run -d windows
```

---

## Gặp lỗi?

### Lỗi: "flutter: command not found"

→ Restart terminal sau khi thêm PATH

### Lỗi: "Visual Studio not found"

→ Cài Visual Studio 2022 Community với C++ workload

### Lỗi: "Android SDK not found"

→ Không sao, bạn chỉ cần chạy trên Windows desktop

---

## Thời gian cài đặt ước tính:

- Tải Flutter: 5-10 phút
- Cài Visual Studio: 15-20 phút
- Setup và chạy app: 5 phút

**Tổng: ~30-40 phút**
