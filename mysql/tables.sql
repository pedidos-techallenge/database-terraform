
    SET @db_name = 'dbtechchallange';

    SET @sql = CONCAT('CREATE DATABASE IF NOT EXISTS ', @db_name);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    USE dbtechchallange;
       
    CREATE TABLE IF NOT EXISTS dbtechchallange.order (
    `id` VARCHAR(255) NOT NULL,
    `number_order` INT NOT NULL,
    `status` VARCHAR(50) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
    );

    CREATE TABLE IF NOT EXISTS dbtechchallange.item (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `order_id` VARCHAR(255) NOT NULL,
        `sku` VARCHAR(255) NOT NULL,
        `quantity` INT NOT NULL,
        `unit_value` DECIMAL(10, 0) NOT NULL,
        `total_value` DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_value) STORED,
        FOREIGN KEY (`order_id`) REFERENCES `order`(`id`)
    );

    CREATE TABLE IF NOT EXISTS dbtechchallange.payment (
        `id` VARCHAR(255) NOT NULL,
        `order_id` VARCHAR(255) NOT NULL,
        `value` DECIMAL(10, 2) NOT NULL,
        `method` VARCHAR(100) NOT NULL,
        `date_payment` VARCHAR(100) NOT NULL,
        `gateway_payment` VARCHAR(100) NOT NULL,
        `status` VARCHAR(100) NOT NULL,
        `reading_code` VARCHAR(500) NOT NULL,
        `processing_code` VARCHAR(50) NOT NULL,
        PRIMARY KEY (`id`),
        FOREIGN KEY (`order_id`) REFERENCES `order`(`id`)
    );

    CREATE TABLE IF NOT EXISTS dbtechchallange.product (
        `sku` VARCHAR(100) NOT NULL,
        `name` VARCHAR(100) NOT NULL,
        `description` VARCHAR(255) NOT NULL,
        `category` VARCHAR(100) NOT NULL,
        `price` DECIMAL(10, 2) NOT NULL,
        `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`sku`)
    );

    CREATE TABLE IF NOT EXISTS dbtechchallange.customer (
        `cpf` VARCHAR(20) NOT NULL,
        `name` VARCHAR(100) NOT NULL,
        `email` VARCHAR(100) NOT NULL,
        `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`cpf`)
    );