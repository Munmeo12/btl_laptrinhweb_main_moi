-- Import MỘT LẦN trên MySQL trống: schema + dữ liệu mẫu + dữ liệu demo
CREATE DATABASE IF NOT EXISTS nhip_khoa
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE nhip_khoa;

CREATE TABLE roles (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id TINYINT UNSIGNED NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    status ENUM('active', 'locked') NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(150) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL UNIQUE,
    description TEXT NULL,
    status ENUM('active', 'hidden') NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE posts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    author_id INT UNSIGNED NOT NULL,
    reviewer_id INT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    summary TEXT NOT NULL,
    thumbnail VARCHAR(255) NULL,
    content LONGTEXT NOT NULL,
    status ENUM('draft', 'pending', 'published', 'rejected') NOT NULL DEFAULT 'draft',
    editor_note TEXT NULL,
    published_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_posts_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_posts_author
        FOREIGN KEY (author_id) REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_posts_reviewer
        FOREIGN KEY (reviewer_id) REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE comments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NULL,
    content TEXT NOT NULL,
    status ENUM('pending', 'approved', 'hidden') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_post
        FOREIGN KEY (post_id) REFERENCES posts(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE impact_box_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    post_id INT UNSIGNED NOT NULL,
    note VARCHAR(500) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_impact_box_user_post UNIQUE (user_id, post_id),
    CONSTRAINT fk_impact_box_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_impact_box_post
        FOREIGN KEY (post_id) REFERENCES posts(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_posts_status_published ON posts(status, published_at);
CREATE INDEX idx_posts_category ON posts(category_id);
CREATE INDEX idx_comments_post_status ON comments(post_id, status);

-- Đề 2.3 yêu cầu CRUD "chuyên mục, bài viết và thẻ" nhưng CSDL cũ chưa có thẻ.
-- Quan hệ nhiều-nhiều: một bài có nhiều thẻ, một thẻ gắn cho nhiều bài.
CREATE TABLE IF NOT EXISTS tags (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS post_tags (
    post_id INT UNSIGNED NOT NULL,
    tag_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (post_id, tag_id),
    CONSTRAINT fk_post_tags_post
        FOREIGN KEY (post_id) REFERENCES posts(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_post_tags_tag
        FOREIGN KEY (tag_id) REFERENCES tags(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_post_tags_tag ON post_tags(tag_id);

-- Độc giả gửi yêu cầu làm Tác giả, Admin duyệt hoặc từ chối.
-- pending_flag: cột sinh tự động = 1 khi yêu cầu đang chờ, NULL khi đã xử lý.
-- UNIQUE(user_id, pending_flag) bảo đảm mỗi người chỉ có TỐI ĐA MỘT yêu cầu đang chờ
-- (NULL không bị tính trùng nên lịch sử đã duyệt/từ chối được lưu thoải mái).
CREATE TABLE IF NOT EXISTS author_requests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    contact VARCHAR(100) NULL,
    topics VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    sample_link VARCHAR(255) NULL,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    admin_note VARCHAR(500) NULL,
    reviewed_by INT UNSIGNED NULL,
    reviewed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    pending_flag TINYINT UNSIGNED
        GENERATED ALWAYS AS (CASE WHEN status = 'pending' THEN 1 ELSE NULL END) STORED,
    CONSTRAINT uq_author_requests_one_pending UNIQUE (user_id, pending_flag),
    CONSTRAINT fk_author_requests_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_author_requests_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_author_requests_status ON author_requests(status, created_at);

USE nhip_khoa;

INSERT INTO roles (id, code, name) VALUES
    (1, 'admin', 'Quản trị viên'),
    (2, 'editor', 'Biên tập viên'),
    (3, 'author', 'Tác giả'),
    (4, 'reader', 'Độc giả');

INSERT INTO users (
    id,
    role_id,
    email,
    password_hash,
    full_name,
    status,
    created_at
) VALUES
    (1, 1, 'admin@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Trần Nguyễn Bình Nguyên', 'active', '2026-08-20 08:00:00'),
    (2, 2, 'quynh@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Trần Hà Như Quỳnh', 'active', '2026-08-20 08:10:00'),
    (3, 3, 'tuyet@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Đặng Ánh Tuyết', 'active', '2026-08-20 08:20:00'),
    (4, 4, 'ly@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Khổng Thị Lý', 'active', '2026-08-20 08:30:00'),
    (5, 3, 'khoa.locked@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Nguyễn Minh Khoa', 'locked', '2026-08-20 08:40:00'),
    (6, 4, 'lan.locked@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Phạm Hoàng Lan', 'locked', '2026-08-20 08:50:00');

INSERT INTO categories (id, slug, name, status) VALUES
    (1, 'tin-khoa', 'Tin khoa', 'active'),
    (2, 'hoc-tap', 'Học tập', 'active'),
    (3, 'co-hoi', 'Cơ hội', 'active'),
    (4, 'su-kien', 'Sự kiện', 'active');

INSERT INTO posts (
    id,
    category_id,
    author_id,
    reviewer_id,
    title,
    slug,
    summary,
    content,
    status,
    published_at,
    created_at
) VALUES
    (1, 1, 3, 2, 'Sinh viên học lập trình web như thế nào?', 'sinh-vien-hoc-lap-trinh-web', 'Một số kinh nghiệm học PHP và MySQL cho người mới.', 'Bài viết chia sẻ cách thực hành từng bước với PHP, MySQL và GitHub.', 'published', '2026-08-22 09:00:00', '2026-08-21 08:00:00'),
    (2, 2, 3, NULL, 'Thiết kế cơ sở dữ liệu cho website tin tức', 'thiet-ke-csdl-website-tin-tuc', 'Giới thiệu các bảng chính và mối quan hệ trong Nhịp Khoa.', 'Nội dung đang được tác giả hoàn thiện trước khi gửi duyệt.', 'draft', NULL, '2026-08-23 10:00:00');

INSERT INTO comments (post_id, user_id, content, status, created_at) VALUES
    (1, 4, 'Bài viết dễ hiểu và có ví dụ thực tế.', 'approved', '2026-08-22 10:00:00'),
    (1, 2, 'Cần bổ sung thêm ví dụ về JOIN.', 'pending', '2026-08-22 10:15:00');

INSERT INTO impact_box_items (user_id, post_id, note, created_at) VALUES
    (4, 1, 'Đọc lại phần hướng dẫn MySQL trước buổi học.', '2026-08-22 10:30:00');

USE nhip_khoa;

-- Chạy SAU seed.sql. Mật khẩu mọi tài khoản mẫu: Admin@123
-- Thêm Tác giả B để kiểm thử "Tác giả A không sửa được bài của Tác giả B".
INSERT INTO users (id, role_id, email, password_hash, full_name, status, created_at) VALUES
    (7, 3, 'tacgia.b@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Lê Quốc Bảo', 'active', '2026-08-20 09:00:00');

INSERT INTO users (id, role_id, email, password_hash, full_name, status, created_at) VALUES
    (8, 4, 'docgia.demo@nhipkhoa.vn', '$2y$10$5qOBuv285ychc3kts46L7OsmFyodolU33/K0T8QAo3dczDCzkqFga', 'Phan Thu Hà', 'active', '2026-08-26 09:00:00');

INSERT INTO tags (id, slug, name) VALUES
    (1, 'php', 'PHP'),
    (2, 'mysql', 'MySQL'),
    (3, 'hoc-bong', 'Học bổng'),
    (4, 'thuc-tap', 'Thực tập'),
    (5, 'workshop', 'Workshop'),
    (6, 'github', 'GitHub');

-- Đủ 4 trạng thái bài viết: draft / pending / published / rejected
INSERT INTO posts (id, category_id, author_id, reviewer_id, title, slug, summary, content, status, editor_note, published_at, created_at) VALUES
    (3, 2, 3, NULL, 'Cách ôn thi môn Cơ sở dữ liệu hiệu quả', 'cach-on-thi-co-so-du-lieu', 'Lộ trình ôn tập từ chuẩn hóa đến JOIN.', 'Bài đang chờ biên tập viên duyệt.', 'pending', NULL, NULL, '2026-08-24 08:00:00'),
    (4, 1, 3, 2, 'Bài viết chưa đạt yêu cầu', 'bai-viet-chua-dat-yeu-cau', 'Bài bị từ chối để kiểm thử luồng chỉnh sửa.', 'Nội dung quá ngắn.', 'rejected', 'Cần bổ sung nguồn tham khảo và ví dụ minh họa.', NULL, '2026-08-24 09:00:00'),
    (5, 3, 7, 2, 'Học bổng toàn phần cho sinh viên CNTT', 'hoc-bong-toan-phan-cntt', 'Thông tin học bổng và hạn nộp hồ sơ.', 'Chi tiết điều kiện, hồ sơ và hạn nộp học bổng.', 'published', NULL, '2026-08-25 09:00:00', '2026-08-25 07:00:00'),
    (6, 3, 7, NULL, 'Bản nháp tuyển thực tập sinh', 'ban-nhap-tuyen-thuc-tap-sinh', 'Bản nháp của Tác giả B, chưa gửi duyệt.', 'Nội dung đang soạn.', 'draft', NULL, NULL, '2026-08-25 10:00:00'),
    (7, 4, 7, 2, 'Workshop Git và GitHub cho người mới', 'workshop-git-github-nguoi-moi', 'Hướng dẫn làm việc nhóm với Git.', 'Buổi workshop thực hành tạo repo, branch và pull request.', 'published', NULL, '2026-08-26 14:00:00', '2026-08-26 08:00:00'),
    (8,  1, 3, 2, 'Khoa công bố lịch thi học kỳ', 'khoa-cong-bo-lich-thi-hoc-ky', 'Lịch thi chính thức học kỳ này.', 'Sinh viên xem lịch thi tại cổng thông tin.', 'published', NULL, '2026-08-27 08:00:00', '2026-08-27 07:00:00'),
    (9,  1, 3, 2, 'Thông báo đăng ký học phần', 'thong-bao-dang-ky-hoc-phan', 'Thời gian và hướng dẫn đăng ký học phần.', 'Đăng ký từ ngày 20/05 trên hệ thống.', 'published', NULL, '2026-08-28 08:00:00', '2026-08-28 07:00:00'),
    (10, 1, 3, 2, 'Kết quả cuộc thi lập trình sinh viên', 'ket-qua-cuoc-thi-lap-trinh', 'Danh sách đội đạt giải.', 'Chúc mừng các đội đã đạt giải.', 'published', NULL, '2026-08-29 08:00:00', '2026-08-29 07:00:00'),
    (11, 1, 7, 2, 'Phòng máy mở cửa thêm buổi tối', 'phong-may-mo-cua-buoi-toi', 'Lịch mở phòng máy mới.', 'Phòng máy mở đến 21h các ngày trong tuần.', 'published', NULL, '2026-08-30 08:00:00', '2026-08-30 07:00:00'),
    (12, 1, 7, 2, 'Ra mắt câu lạc bộ lập trình', 'ra-mat-cau-lac-bo-lap-trinh', 'CLB lập trình tuyển thành viên.', 'Đăng ký tham gia trước cuối tháng.', 'published', NULL, '2026-08-31 08:00:00', '2026-08-31 07:00:00'),
    (13, 1, 3, 2, 'Thay đổi quy định đồ án tốt nghiệp', 'thay-doi-quy-dinh-do-an-tot-nghiep', 'Điểm mới trong quy định đồ án.', 'Sinh viên đọc kỹ quy định mới trước khi đăng ký.', 'published', NULL, '2026-09-01 08:00:00', '2026-09-01 07:00:00');

INSERT INTO post_tags (post_id, tag_id) VALUES
    (1, 1), (1, 2), (1, 6),
    (2, 2),
    (3, 2),
    (5, 3), (5, 4),
    (7, 5), (7, 6);

-- Bình luận đủ 3 trạng thái; bình luận chứa script để kiểm thử mã hóa khi hiển thị
INSERT INTO comments (post_id, user_id, content, status, created_at) VALUES
    (1, 4, 'Cảm ơn tác giả, bài rất hữu ích.', 'approved', '2026-08-22 11:00:00'),
    (1, 4, '<script>alert("XSS")</script>', 'pending', '2026-08-22 11:30:00'),
    (5, 4, 'Cho mình hỏi hạn nộp hồ sơ là ngày nào?', 'pending', '2026-08-25 12:00:00'),
    (7, 4, 'Bình luận vi phạm, quảng cáo spam.', 'hidden', '2026-08-26 16:00:00'),
    (7, 2, 'Workshop rất thực tế.', 'approved', '2026-08-26 17:00:00');

INSERT INTO impact_box_items (user_id, post_id, note, created_at) VALUES
    (4, 5, 'Chuẩn bị hồ sơ trước hạn nộp.', '2026-08-25 13:00:00'),
    (4, 7, NULL, '2026-08-26 18:00:00');

-- Yêu cầu làm tác giả: Phan Thu Hà (id 8) đang chờ duyệt; Khổng Thị Lý (id 4) từng bị từ chối.
-- Muốn thử gửi yêu cầu mới, đăng nhập bằng ly@nhipkhoa.vn (Độc giả, hiện không có yêu cầu chờ).
INSERT INTO author_requests (user_id, contact, topics, reason, sample_link, status, admin_note, reviewed_by, reviewed_at, created_at) VALUES
    (4, NULL, 'Học tập', 'Em muốn chia sẻ kinh nghiệm học môn lập trình web cho các bạn khóa sau.', NULL, 'rejected', 'Hồ sơ còn sơ sài, hãy bổ sung bài viết mẫu rồi gửi lại.', 1, '2026-08-27 09:00:00', '2026-08-26 20:00:00'),
    (8, 'Zalo 0900000000', 'Học bổng, thực tập, workshop', 'Mình là sinh viên năm 3, thường xuyên tham gia workshop và muốn đăng bài tổng hợp học bổng, cơ hội thực tập cho các bạn trong khoa.', 'https://example.com/bai-mau', 'pending', NULL, NULL, NULL, '2026-08-28 08:30:00');
