# Cấu hình Gemini API

## Hướng dẫn lấy API Key

1. Truy cập [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Đăng nhập bằng tài khoản Google của bạn
3. Click "Create API Key"
4. Copy API key vừa tạo

## Cấu hình trong App

1. **Tạo file `.env`** trong thư mục root của project (nếu chưa có):

   ```bash
   cp .env.example .env
   ```

2. **Thêm API key** vào file `.env`:

   ```env
   GEMINI_API_KEY=AIzaSy...your_actual_api_key_here
   ```

3. **File `.env` đã được thêm vào `.gitignore`** nên sẽ không bị commit lên Git

## Cấu trúc files

```
knop_flashcard/
├── .env                 # API key của bạn (KHÔNG commit)
├── .env.example         # Template file (có thể commit)
├── .gitignore           # Đã có .env trong list
└── lib/
    └── core/
        └── gemini_service.dart  # Đọc từ dotenv
```

## Tính năng đã implement

### 1. Chat Bubble (Góc dưới bên phải)

- Click vào bubble để mở cửa sổ chat
- Giao tiếp trực tiếp với Gemini 2.5 Flash
- Lưu lịch sử hội thoại trong phiên làm việc
- Minimize/expand chat window

### 2. Quiz Popup (Góc trên bên phải)

- Tự động hiện quiz popup sau mỗi 30 phút
- Lấy câu hỏi từ các Knowledge đã có reminder time
- Ưu tiên câu hỏi cần ôn tập (success rate < 60%)
- Minimize/expand quiz window

### 3. LLM Answer Evaluation

- Sử dụng Gemini để đánh giá câu trả lời dài
- Không chỉ so sánh string matching như vocabulary
- Trả về:
  - `isCorrect`: Đúng/sai
  - `score`: Điểm số 0-100
  - `feedback`: Nhận xét chi tiết
  - `suggestion`: Gợi ý cải thiện

### 4. LLM Comments sau khi trả lời

- Sau khi submit answer, LLM sẽ đưa ra nhận xét
- Hiển thị score badge (màu xanh nếu đúng, cam nếu chưa tốt)
- Feedback chi tiết về câu trả lời
- Gợi ý để cải thiện

### 5. Button "Hỏi thêm AI"

- Xuất hiện sau khi có evaluation
- Mở dialog để hỏi follow-up questions
- Context-aware: AI biết về câu hỏi quiz và câu trả lời của bạn
- Giải thích sâu hơn về chủ đề

## Quiz Scheduler

Scheduler chạy ở background với cơ chế:

1. **Timer**: Kiểm tra mỗi 30 phút (có thể thay đổi)
2. **Filter**: Chỉ lấy Knowledge có `reminderTime` đã đến
3. **Prioritize**: Ưu tiên câu hỏi:
   - Có `needsPractice` (success rate < 60% hoặc chưa làm đủ 3 lần)
   - Câu hỏi ít được hiển thị nhất
4. **Random**: Chọn ngẫu nhiên Knowledge từ danh sách đủ điều kiện

### Test Quiz ngay lập tức

Thêm button test vào UI (optional):

```dart
ElevatedButton(
  onPressed: () {
    _quizScheduler.triggerQuiz(); // Test với random knowledge
    // hoặc
    _quizScheduler.triggerQuiz(knowledgeId: 1); // Test với knowledge cụ thể
  },
  child: Text('Test Quiz'),
)
```

## Thay đổi Quiz Interval

Trong `new_home_screen.dart`, file `initState()`:

```dart
// Thay đổi từ 30 phút sang 15 phút
_quizScheduler.start(interval: const Duration(minutes: 15));

// Hoặc test với 1 phút
_quizScheduler.start(interval: const Duration(minutes: 1));
```

## Gemini Model

Hiện tại sử dụng `gemini-2.0-flash-exp`:

- Nhanh, lightweight
- Phù hợp cho chat và evaluation realtime
- Free tier: 1500 requests/day

Nếu cần model mạnh hơn, thay đổi trong `gemini_service.dart`:

```dart
static const String _model = 'gemini-1.5-pro'; // Model mạnh hơn
```

## Lưu ý

- **API Key bảo mật**: Không commit API key lên Git
- **Rate limit**: Gemini free tier có giới hạn requests
- **Error handling**: App sẽ hiển thị message lỗi thân thiện nếu API fail
- **Network**: Cần internet để gọi Gemini API

## Troubleshooting

### 1. Chat bubble không phản hồi

- Kiểm tra API key đã đúng chưa
- Check console log: `Gemini API Error: ...`
- Verify internet connection

### 2. Quiz không tự động popup

- Đảm bảo có Knowledge với `reminderTime` được set
- Check log: `Quiz Scheduler Error: ...`
- Thử test manual với `triggerQuiz()`

### 3. Evaluation không hoạt động

- Gemini API có thể trả về format không đúng JSON
- Check log: `Gemini Evaluation Error: ...`
- Code đã handle cleanup JSON response

## Files đã tạo

- `lib/core/gemini_service.dart` - Service gọi Gemini API
- `lib/widgets/chat_bubble.dart` - Chat bubble widget
- `lib/widgets/quiz_popup.dart` - Quiz popup widget với LLM evaluation
- `lib/core/quiz_scheduler.dart` - Background scheduler
- Updated `lib/screens/new_home_screen.dart` - Integration

## Next Steps (Optional)

1. **Persistent Chat History**: Lưu chat history vào database
2. **Custom Prompts**: Cho phép user customize system prompts
3. **Voice Input**: Thêm speech-to-text cho chat
4. **Quiz Analytics**: Hiển thị thống kê về quiz performance với LLM scores
5. **Multi-language**: Support nhiều ngôn ngữ cho chat và evaluation
