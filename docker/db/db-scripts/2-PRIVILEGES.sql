CREATE USER 'admincdb' IDENTIFIED BY 'qwerty1234';

GRANT ALL PRIVILEGES ON `test_database`.* TO 'admincdb' WITH GRANT OPTION;

FLUSH PRIVILEGES;