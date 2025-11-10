# 🛠️ Cài đặt Visual Studio Build Tools cho Flutter Windows

## ⚠️ VẤN ĐỀ HIỆN TẠI

Flutter cần Visual Studio C++ toolchain để build Windows apps, nhưng đang thiếu:

- ❌ MSVC v142 - VS 2019 C++ x64/x86 build tools
- ❌ C++ CMake tools for Windows
- ❌ Windows 10 SDK

---

## 🎯 GIẢI PHÁP 1: Modify Visual Studio hiện tại (KHUYẾN NGHỊ)

Bạn đã có Visual Studio Community 2022, chỉ cần thêm components:

### Bước 1: Mở Visual Studio Installer

- Nhấn `Windows + S` → Gõ "Visual Studio Installer"
- Hoặc vào: `D:\Extra download\visualstudio_package`

### Bước 2: Modify Visual Studio

1. Click nút **"Modify"** bên cạnh Visual Studio Community 2022
2. Trong tab **"Workloads"**, tích chọn:
   - ✅ **Desktop development with C++**

### Bước 3: Chọn các components bắt buộc

Trong tab **"Individual components"**, đảm bảo có:

- ✅ **MSVC v143 - VS 2022 C++ x64/x86 build tools** (mới nhất)
  - Hoặc: MSVC v142 - VS 2019 C++ build tools
- ✅ **C++ CMake tools for Windows**
- ✅ **Windows 10 SDK** (10.0.19041.0 hoặc mới hơn)
- ✅ **C++ ATL for latest v143 build tools** (optional nhưng tốt)

### Bước 4: Cài đặt

- Click **"Modify"** → Đợi cài đặt (khoảng 5-15 phút)
- Khởi động lại VS Code sau khi xong

---

## 🎯 GIẢI PHÁP 2: Cài Build Tools độc lập (Nhẹ hơn)

Nếu không muốn cài full Visual Studio:

### Tải Build Tools

```powershell
# Mở PowerShell và chạy:
Start-Process "https://aka.ms/vs/17/release/vs_BuildTools.exe" -Wait
```

### Sau khi tải xong, chạy installer và chọn:

1. **Desktop development with C++** workload
2. Components tương tự như trên

---

## ✅ SAU KHI CÀI XONG

### 1. Kiểm tra lại:

```bash
cd /d/Code/Important/project/knop_flashcard
"D:/Extra download/flutter/bin/flutter" doctor -v
```

Bạn sẽ thấy:

```
[√] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.11.4)
    • Visual Studio at D:\Extra download\visualstudio_package
    • Visual Studio Community 2022 version 17.11.35312.102
    • All necessary components installed
```

### 2. Chạy app:

```bash
"D:/Extra download/flutter/bin/flutter" run -d windows
```

---

## 📊 YÊU CẦU HỆ THỐNG

- **Dung lượng:** ~6-8 GB cho C++ workload
- **Thời gian:** 10-20 phút (tùy tốc độ mạng)
- **Windows:** 10 version 1809 trở lên

---

## 🆘 NẾU GẶP VẤN ĐỀ

### Lỗi: "No suitable Visual Studio toolchain"

→ Đảm bảo đã cài **MSVC v142 hoặc v143**

### Lỗi: "CMake not found"

→ Cài **C++ CMake tools for Windows**

### Lỗi: "Windows SDK not found"

→ Cài **Windows 10 SDK** (phiên bản 10.0.19041.0 trở lên)

---

## 🔗 LINKS HỮU ÍCH

- Visual Studio Community: https://visualstudio.microsoft.com/vs/community/
- Build Tools only: https://aka.ms/vs/17/release/vs_BuildTools.exe
- Flutter docs: https://docs.flutter.dev/get-started/install/windows

---

**Sau khi cài xong, chạy lại app Knop sẽ work ngay! 🚀**
