CREATE TABLE `foreignhost` (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`ipv4` VARCHAR( 16 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`fqdn` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
INDEX ( `ipv4` )
) ENGINE = innodb CHARACTER SET utf8 COLLATE utf8_general_ci;
