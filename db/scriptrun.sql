CREATE TABLE `scriptrun` (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
`hostsource` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`hosttarget` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`timeunixstart` INT NULL ,
`timeunixstop` INT NULL ,
`timehumanstart` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
`timehumanstop` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,
INDEX ( `hostsource` , `hosttarget` )
) ENGINE = innodb CHARACTER SET utf8 COLLATE utf8_general_ci;
