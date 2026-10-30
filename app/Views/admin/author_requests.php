<?php
declare(strict_types=1);
/** @var array $requests */
/** @var array $counts */
/** @var string $filter */
/** @var string $notice */
/** @var string $error */
/** @var string $databaseError */
/** @var array $roleNames */

$statusLabels = ['pending' => 'Chờ duyệt', 'approved' => 'Đã duyệt', 'rejected' => 'Đã từ chối'];
$tabs = [
    'pending' => 'Chờ duyệt (' . (int) $counts['pending'] . ')',
    'approved' => 'Đã duyệt (' . (int) $counts['approved'] . ')',
    'rejected' => 'Đã từ chối (' . (int) $counts['rejected'] . ')',
    'all' => 'Tất cả',
];
$dateFormat = static fn(?string $value): string => $value ? date('d/m/Y H:i', strtotime($value)) : '';
?>
<style>
.ar-tabs{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:18px}
.ar-tabs a{padding:8px 14px;border:1px solid #dcd1cb;border-radius:999px;background:#fff;color:#786d68;font-size:11px;font-weight:600;text-decoration:none}
.ar-tabs a:hover{border-color:#8c3026;color:#8c3026}
.ar-tabs a.active{color:#fff;background:#8c3026;border-color:#8c3026}
.status-chip.pending{color:#6e4f1b;background:#fff3d8}
.status-chip.approved{color:#286448;background:#e8f5ee}
.status-chip.rejected{color:#8b3330;background:#fae7e6}
.ar-list{display:grid;gap:14px}
.ar-item{padding:20px 22px;background:#fff;border:1px solid #eadfd9;border-radius:12px;box-shadow:0 7px 22px rgba(74,48,40,.04)}
.ar-item header{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:14px}
.ar-item dl{display:grid;grid-template-columns:140px 1fr;gap:7px 14px;margin:0 0 14px;font-size:12px;line-height:1.6}
.ar-item dt{color:#8b807b}
.ar-item dd{margin:0;color:#2f2724;word-break:break-word}
.ar-item dd a{color:#8c3026}
.ar-actions{display:flex;gap:10px;align-items:flex-start;flex-wrap:wrap;padding-top:14px;border-top:1px solid #f0e9e6}
.ar-actions form{margin:0}
.ar-approve,.ar-reject{height:34px;padding:0 16px;border:0;border-radius:7px;cursor:pointer;font:600 11px Inter,sans-serif}
.ar-approve{color:#fff;background:#37765a}
.ar-approve:hover{background:#2a5e47}
.ar-reject{color:#983b35;background:#fae8e6}
.ar-reject:hover{filter:brightness(.96)}
.ar-reject-form{display:flex;gap:8px;flex:1;min-width:260px}
.ar-reject-form input{flex:1;height:34px;padding:0 10px;border:1px solid #dcd1cb;border-radius:7px;font:11px Inter,sans-serif}
.ar-reject-form input:focus{border-color:#8c3026;outline:0;box-shadow:0 0 0 3px rgba(140,48,38,.08)}
.ar-result{padding:11px 14px;border-left:3px solid #8c3026;background:#fcf6f4;font-size:11px;line-height:1.6;color:#4a3028}
@media(max-width:700px){.ar-item dl{grid-template-columns:1fr}}
</style>

<section class="admin-heading"><div><p>PHÂN QUYỀN NGƯỜI DÙNG</p><h1>Yêu cầu làm tác giả</h1><span>Xem hồ sơ của Độc giả, duyệt để nâng lên Tác giả hoặc từ chối kèm lý do.</span></div></section>

<?php if ($notice !== ''): ?><div class="admin-alert success"><?= e($notice) ?></div><?php endif; ?>
<?php if ($error !== ''): ?><div class="admin-alert error"><?= e($error) ?></div><?php endif; ?>
<?php if ($databaseError !== ''): ?><div class="admin-alert error"><?= e($databaseError) ?></div><?php endif; ?>

<nav class="ar-tabs" aria-label="Lọc theo trạng thái">
    <?php foreach ($tabs as $key => $label): ?>
        <a class="<?= $filter === $key ? 'active' : '' ?>" href="?status=<?= e($key) ?>"><?= e($label) ?></a>
    <?php endforeach; ?>
</nav>

<div class="ar-list">
    <?php foreach ($requests as $item): $isPending = $item['status'] === 'pending'; ?>
        <article class="ar-item">
            <header>
                <div class="user-cell">
                    <span><?= e(mb_strtoupper(mb_substr((string) $item['full_name'], 0, 1))) ?></span>
                    <div><b><?= e($item['full_name']) ?></b><small><?= e($item['email']) ?> · hiện là <?= e($roleNames[$item['role']] ?? $item['role']) ?></small></div>
                </div>
                <span class="status-chip <?= e($item['status']) ?>"><?= e($statusLabels[$item['status']] ?? $item['status']) ?></span>
            </header>

            <dl>
                <dt>Gửi lúc</dt><dd><?= e($dateFormat($item['created_at'])) ?></dd>
                <dt>Chủ đề muốn viết</dt><dd><?= e($item['topics']) ?></dd>
                <dt>Lý do</dt><dd><?= nl2br(e($item['reason'])) ?></dd>
                <?php if (!empty($item['sample_link'])): ?>
                    <dt>Link bài mẫu</dt><dd><a href="<?= e($item['sample_link']) ?>" target="_blank" rel="noopener noreferrer nofollow"><?= e($item['sample_link']) ?></a></dd>
                <?php endif; ?>
                <?php if (!empty($item['contact'])): ?><dt>Liên hệ thêm</dt><dd><?= e($item['contact']) ?></dd><?php endif; ?>
                <?php if ($item['user_status'] !== 'active'): ?><dt>Cảnh báo</dt><dd>Tài khoản đang bị khóa.</dd><?php endif; ?>
            </dl>

            <?php if ($isPending): ?>
                <div class="ar-actions">
                    <form method="post" onsubmit="return confirm('Nâng tài khoản này lên Tác giả?')">
                        <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                        <input type="hidden" name="request_id" value="<?= (int) $item['id'] ?>">
                        <input type="hidden" name="back_status" value="<?= e($filter) ?>">
                        <input type="hidden" name="action" value="approve">
                        <button class="ar-approve" type="submit">Duyệt làm tác giả</button>
                    </form>
                    <form class="ar-reject-form" method="post">
                        <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                        <input type="hidden" name="request_id" value="<?= (int) $item['id'] ?>">
                        <input type="hidden" name="back_status" value="<?= e($filter) ?>">
                        <input type="hidden" name="action" value="reject">
                        <input type="text" name="admin_note" maxlength="500" placeholder="Lý do từ chối (bắt buộc, 5-500 ký tự)" required>
                        <button class="ar-reject" type="submit">Từ chối</button>
                    </form>
                </div>
            <?php else: ?>
                <div class="ar-result">
                    <?= e($statusLabels[$item['status']] ?? '') ?> bởi <strong><?= e($item['reviewer_name'] ?? 'Quản trị viên') ?></strong>
                    lúc <?= e($dateFormat($item['reviewed_at'])) ?>
                    <?php if (!empty($item['admin_note'])): ?><br>Lý do: <?= nl2br(e($item['admin_note'])) ?><?php endif; ?>
                </div>
            <?php endif; ?>
        </article>
    <?php endforeach; ?>

    <?php if ($requests === [] && $databaseError === ''): ?>
        <div class="admin-panel"><div class="admin-empty"><strong>Không có yêu cầu nào</strong><span>Chưa có yêu cầu trong mục này.</span></div></div>
    <?php endif; ?>
</div>
