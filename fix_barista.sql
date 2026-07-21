USE khoga_coffee_shop;
GO
UPDATE users 
SET password_hash = '$2a$10$GAF2.Z/fSC3VhCc0F7HSL./D4Lx3HTYJG1afmKQS9qEeGdDLfvjeu',
    failed_attempts = 0,
    lock_expiry_at = NULL,
    must_change_password = 1
WHERE username = 'barista';
GO
SELECT username, failed_attempts, password_hash, must_change_password FROM users WHERE username = 'barista';
GO
