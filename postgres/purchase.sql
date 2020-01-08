CREATE DATABASE purchase;
\c purchase
CREATE TABLE user_purchase (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    item VARCHAR(30) NOT NULL,
    purchase_cost INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    modified TIMESTAMP NOT NULL DEFAULT NOW()
);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (2, 'book', 10);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (3, 'bell', 1340);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (4, 'house', 523);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (5, 'rock', 232);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (6, 'car', 209);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (7, 'glasses', 150);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (8, 'book', 10);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (9, 'book', 102);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (10, 'book', 104);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (11, 'book', 1032);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (12, 'book', 105);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (13, 'book', 102);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (14, 'book', 103);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (15, 'book', 990);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (16, 'pen', 100);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (17, 'pen', 100);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (18, 'pen', 100);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (19, 'pen', 100);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (20, 'flight ticket', 200);
INSERT INTO user_purchase (user_id, item, purchase_cost) values (21, 'flight ticket', 200);

CREATE OR REPLACE FUNCTION update_modified_column() 
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = now();
    RETURN NEW; 
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_purchase_modtime BEFORE UPDATE ON user_purchase FOR EACH ROW EXECUTE PROCEDURE  update_modified_column();