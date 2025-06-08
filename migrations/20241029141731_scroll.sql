-- Add migration script here

CREATE TABLE scroll (
    id SERIAL PRIMARY KEY,
    rank level NOT NULL,
    jutsu VARCHAR(255) NOT NULL,
    usage VARCHAR(255) NOT NULL
);