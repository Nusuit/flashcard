#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Knop Flashcard - Python Demo Version
Chạy demo này để thấy cách ứng dụng hoạt động
"""

import json
import random
import sqlite3
import os
from datetime import datetime
from pathlib import Path

class KnopDemo:
    def __init__(self):
        self.db_path = "knop_demo.db"
        self.init_database()
        
    def init_database(self):
        """Khởi tạo database SQLite"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Tạo bảng vocabulary
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS vocabulary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                language TEXT NOT NULL,
                word TEXT NOT NULL,
                pinyin TEXT,
                meaning_vi TEXT NOT NULL,
                example_sentence TEXT,
                times_correct INTEGER DEFAULT 0,
                times_shown INTEGER DEFAULT 0,
                created_at TEXT NOT NULL
            )
        """)
        
        # Tạo bảng knowledge
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS knowledge (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)
        
        # Tạo bảng quiz_questions
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS quiz_questions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                knowledge_id INTEGER,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                question_type TEXT DEFAULT 'open',
                times_correct INTEGER DEFAULT 0,
                times_shown INTEGER DEFAULT 0
            )
        """)
        
        conn.commit()
        conn.close()
        print("✅ Database đã được khởi tạo")
    
    def add_sample_data(self):
        """Thêm dữ liệu mẫu"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Xóa dữ liệu cũ
        cursor.execute("DELETE FROM vocabulary")
        cursor.execute("DELETE FROM knowledge")
        cursor.execute("DELETE FROM quiz_questions")
        
        # Thêm từ vựng tiếng Anh
        vocab_en = [
            ("en", "apple", None, "quả táo", "I eat an apple every day"),
            ("en", "book", None, "quyển sách", "She is reading a book"),
            ("en", "computer", None, "máy tính", "I work on my computer"),
            ("en", "hello", None, "xin chào", "Hello, how are you?"),
            ("en", "thank you", None, "cảm ơn", "Thank you for your help"),
        ]
        
        for item in vocab_en:
            cursor.execute("""
                INSERT INTO vocabulary (language, word, pinyin, meaning_vi, example_sentence, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (*item, datetime.now().isoformat()))
        
        # Thêm từ vựng tiếng Trung
        vocab_cn = [
            ("cn", "苹果", "píngguǒ", "quả táo", "我每天吃一个苹果"),
            ("cn", "书", "shū", "quyển sách", "她在看书"),
            ("cn", "电脑", "diànnǎo", "máy tính", "我在电脑上工作"),
            ("cn", "你好", "nǐ hǎo", "xin chào", "你好，你好吗？"),
            ("cn", "谢谢", "xièxie", "cảm ơn", "谢谢你的帮助"),
        ]
        
        for item in vocab_cn:
            cursor.execute("""
                INSERT INTO vocabulary (language, word, pinyin, meaning_vi, example_sentence, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (*item, datetime.now().isoformat()))
        
        # Thêm knowledge note
        cursor.execute("""
            INSERT INTO knowledge (topic, content, created_at)
            VALUES (?, ?, ?)
        """, (
            "JavaScript Closures",
            "A closure is a function that has access to variables in its outer function's scope, even after the outer function has returned. Closures are created every time a function is created.",
            datetime.now().isoformat()
        ))
        
        knowledge_id = cursor.lastrowid
        
        # Thêm quiz questions
        questions = [
            (knowledge_id, "What is a closure in JavaScript?", "A function that has access to outer scope variables", "open"),
            (knowledge_id, "Closures are created when?", "Every time a function is created", "open"),
            (knowledge_id, "Can closures access outer variables after the outer function returns?", "Yes", "open"),
        ]
        
        for q in questions:
            cursor.execute("""
                INSERT INTO quiz_questions (knowledge_id, question, answer, question_type)
                VALUES (?, ?, ?, ?)
            """, q)
        
        conn.commit()
        conn.close()
        print("✅ Đã thêm dữ liệu mẫu:")
        print(f"   - {len(vocab_en)} từ tiếng Anh")
        print(f"   - {len(vocab_cn)} từ tiếng Trung")
        print(f"   - 1 knowledge note với {len(questions)} câu hỏi")
    
    def get_vocabulary_stats(self):
        """Lấy thống kê từ vựng"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM vocabulary WHERE language='en'")
        en_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM vocabulary WHERE language='cn'")
        cn_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM knowledge")
        knowledge_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM quiz_questions")
        questions_count = cursor.fetchone()[0]
        
        conn.close()
        
        return {
            'english': en_count,
            'chinese': cn_count,
            'knowledge': knowledge_count,
            'questions': questions_count
        }
    
    def generate_quiz(self, count=3):
        """Tạo quiz ngẫu nhiên"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Lấy từ vựng ngẫu nhiên
        cursor.execute("""
            SELECT id, language, word, pinyin, meaning_vi, example_sentence
            FROM vocabulary
            ORDER BY RANDOM()
            LIMIT ?
        """, (count // 2 + 1,))
        
        vocab_items = cursor.fetchall()
        
        # Lấy câu hỏi knowledge
        cursor.execute("""
            SELECT id, question, answer, question_type
            FROM quiz_questions
            ORDER BY RANDOM()
            LIMIT ?
        """, (count // 2,))
        
        knowledge_items = cursor.fetchall()
        
        conn.close()
        
        quiz = []
        
        # Tạo câu hỏi từ vocabulary
        for item in vocab_items:
            vocab_id, lang, word, pinyin, meaning, example = item
            
            # Random quiz mode
            mode = random.choice(['word_to_meaning', 'meaning_to_word'])
            
            if mode == 'word_to_meaning':
                if lang == 'cn' and pinyin:
                    question = f'Từ "{word}" ({pinyin}) nghĩa là gì?'
                else:
                    question = f'Từ "{word}" nghĩa là gì?'
                answer = meaning
            else:
                lang_name = "English" if lang == "en" else "Chinese"
                question = f'Dịch sang {lang_name}: {meaning}'
                answer = word
            
            quiz.append({
                'type': 'vocabulary',
                'id': vocab_id,
                'question': question,
                'answer': answer,
                'example': example
            })
        
        # Thêm câu hỏi knowledge
        for item in knowledge_items:
            q_id, question, answer, q_type = item
            quiz.append({
                'type': 'knowledge',
                'id': q_id,
                'question': question,
                'answer': answer,
                'question_type': q_type
            })
        
        # Trộn câu hỏi
        random.shuffle(quiz)
        
        return quiz[:count]
    
    def record_answer(self, item_type, item_id, is_correct):
        """Ghi lại câu trả lời"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        if item_type == 'vocabulary':
            cursor.execute("""
                UPDATE vocabulary
                SET times_shown = times_shown + 1,
                    times_correct = times_correct + ?
                WHERE id = ?
            """, (1 if is_correct else 0, item_id))
        else:
            cursor.execute("""
                UPDATE quiz_questions
                SET times_shown = times_shown + 1,
                    times_correct = times_correct + ?
                WHERE id = ?
            """, (1 if is_correct else 0, item_id))
        
        conn.commit()
        conn.close()
    
    def take_quiz(self, count=5):
        """Bắt đầu quiz"""
        print("\n" + "="*60)
        print("🎴 KNOP FLASHCARD - QUIZ TIME!")
        print("="*60)
        
        quiz = self.generate_quiz(count)
        
        if not quiz:
            print("❌ Không có câu hỏi nào. Hãy thêm dữ liệu mẫu trước!")
            return
        
        correct = 0
        total = len(quiz)
        
        for i, item in enumerate(quiz, 1):
            print(f"\n📝 Câu {i}/{total}")
            print("-" * 60)
            print(f"❓ {item['question']}")
            
            if item.get('example'):
                print(f"   💡 Ví dụ: {item['example']}")
            
            user_answer = input("\n👉 Câu trả lời của bạn: ").strip()
            
            print(f"\n✅ Đáp án đúng: {item['answer']}")
            
            is_correct = input("Bạn trả lời đúng không? (y/n): ").lower() == 'y'
            
            if is_correct:
                correct += 1
                print("🎉 Tuyệt vời!")
            else:
                print("💪 Cố gắng lần sau!")
            
            # Ghi lại kết quả
            self.record_answer(item['type'], item['id'], is_correct)
        
        # Hiển thị kết quả
        accuracy = (correct / total * 100) if total > 0 else 0
        
        print("\n" + "="*60)
        print("🎊 KẾT QUẢ QUIZ")
        print("="*60)
        print(f"✅ Đúng: {correct}/{total}")
        print(f"📊 Độ chính xác: {accuracy:.1f}%")
        
        if accuracy >= 80:
            print("🌟 Xuất sắc! Bạn làm rất tốt!")
        elif accuracy >= 60:
            print("👍 Tốt lắm! Tiếp tục cố gắng!")
        else:
            print("💪 Đừng bỏ cuộc! Luyện tập nhiều hơn nhé!")
        
        print("="*60)
    
    def show_stats(self):
        """Hiển thị thống kê"""
        stats = self.get_vocabulary_stats()
        
        print("\n" + "="*60)
        print("📊 THỐNG KÊ THƯ VIỆN")
        print("="*60)
        print(f"📖 Từ vựng tiếng Anh: {stats['english']}")
        print(f"🀄 Từ vựng tiếng Trung: {stats['chinese']}")
        print(f"💡 Knowledge notes: {stats['knowledge']}")
        print(f"❓ Câu hỏi: {stats['questions']}")
        print(f"📚 Tổng cộng: {stats['english'] + stats['chinese'] + stats['questions']}")
        print("="*60)
    
    def show_menu(self):
        """Hiển thị menu"""
        while True:
            print("\n" + "="*60)
            print("🎴 KNOP FLASHCARD - DEMO VERSION")
            print("="*60)
            print("1. 📊 Xem thống kê")
            print("2. 🎲 Thêm dữ liệu mẫu")
            print("3. 🎯 Bắt đầu Quiz (3 câu)")
            print("4. 🎓 Bắt đầu Quiz (5 câu)")
            print("5. 📚 Bắt đầu Quiz (10 câu)")
            print("6. ❌ Thoát")
            print("="*60)
            
            choice = input("👉 Chọn chức năng (1-6): ").strip()
            
            if choice == '1':
                self.show_stats()
            elif choice == '2':
                self.add_sample_data()
            elif choice == '3':
                self.take_quiz(3)
            elif choice == '4':
                self.take_quiz(5)
            elif choice == '5':
                self.take_quiz(10)
            elif choice == '6':
                print("\n👋 Cảm ơn bạn đã sử dụng Knop Flashcard!")
                print("💡 Để sử dụng ứng dụng đầy đủ, hãy cài đặt Flutter và chạy:")
                print("   flutter pub get")
                print("   flutter run -d windows")
                break
            else:
                print("❌ Lựa chọn không hợp lệ!")

def main():
    """Hàm chính"""
    print("\n" + "🎴" * 30)
    print("  KNOP FLASHCARD - PYTHON DEMO")
    print("  Ứng dụng học từ vựng và kiến thức thông minh")
    print("🎴" * 30)
    
    demo = KnopDemo()
    
    # Kiểm tra xem đã có dữ liệu chưa
    stats = demo.get_vocabulary_stats()
    if sum(stats.values()) == 0:
        print("\n💡 Chưa có dữ liệu. Thêm dữ liệu mẫu để bắt đầu...")
        demo.add_sample_data()
    
    demo.show_menu()

if __name__ == "__main__":
    main()
