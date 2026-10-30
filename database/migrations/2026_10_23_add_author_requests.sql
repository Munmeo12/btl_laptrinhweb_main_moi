USE nhip_khoa;

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
