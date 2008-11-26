CREATE TABLE `myhost` (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`ipv4` VARCHAR( 16 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`fqdn` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
`workname` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
`operator` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
`email` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL
) ENGINE = innodb CHARACTER SET utf8 COLLATE utf8_general_ci;
