CREATE TABLE `trrunhop` (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`idtrrun` INT NOT NULL ,
`hopposition` TINYINT NOT NULL ,
`ipv4` VARCHAR( 16 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`probe` TINYINT NOT NULL ,
`rtt` FLOAT NULL ,
`error` VARCHAR( 5 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
INDEX ( `idtrrun` , `hopposition` , `ipv4` )
) ENGINE = innodb CHARACTER SET utf8 COLLATE utf8_general_ci;
