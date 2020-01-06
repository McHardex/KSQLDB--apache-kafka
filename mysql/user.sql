CREATE DATABASE user;
use user;
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';
CREATE TABLE user_details (id int auto_increment primary key, user_id int, name varchar(30));
INSERT INTO user_details (user_id, name) values (2, 'Adebisi Oluwabukunmi');
INSERT INTO user_details (user_id, name) values (3, 'Marc Willians');
INSERT INTO user_details (user_id, name) values (4, 'Sola Amaobi');
INSERT INTO user_details (user_id, name) values (5, 'Nomso Amadi');
INSERT INTO user_details (user_id, name) values (6, 'Jide Oketonade');
INSERT INTO user_details (user_id, name) values (7, 'Bola Afe');
INSERT INTO user_details (user_id, name) values (8, 'Boluwatife Osunlola');
INSERT INTO user_details (user_id, name) values (9,  'Caroline Megwe');
INSERT INTO user_details (user_id, name) values (10,  'Kunle Brown');
INSERT INTO user_details (user_id, name) values (11,  'Lola James');
INSERT INTO user_details (user_id, name) values (12,  'Bolatito Samuel');
INSERT INTO user_details (user_id, name) values (13,  'Ola Kehinde');
INSERT INTO user_details (user_id, name) values (14,  'Iseoluwa Ileri');
INSERT INTO user_details (user_id, name) values (15,  'Jonathan Nelson');
