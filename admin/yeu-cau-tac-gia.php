<?php
declare(strict_types=1);
require_once __DIR__ . '/../bootstrap/app.php';
(new App\Controllers\AuthorRequestController(static fn(): PDO => db(), new App\Services\AuthService(), new App\Core\View()))->adminIndex(App\Core\Request::capture());
