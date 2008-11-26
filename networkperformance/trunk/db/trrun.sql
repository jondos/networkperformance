CREATE TABLE `trrun` (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`idscriptrun` INT NOT NULL ,
`timeunix` INT NOT NULL ,
`timehuman` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
INDEX ( `idscriptrun` )
) ENGINE = innodb CHARACTER SET utf8 COLLATE utf8_general_ci;
