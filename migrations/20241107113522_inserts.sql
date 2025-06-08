-- Add migration script here
INSERT INTO scroll (rank, jutsu, usage) VALUES 
('GENIN'::level, 'subsitute', 'dodge attack and bid time for a counter/escape'), ('GENIN'::level, 'one thousand years of death', 'humiliate your opponent'), 
('GENIN'::level, 'bushin no jutsu', 'creates a clone'), 
('GENIN'::level, 'transform', 'change appearance to fool around'), 
('GENIN'::level, 'shadow shuriken', '3 steps attack to catch opponent off guard and create an opening'), 
('CHUUNIN'::level, 'body flicker technique', 'swift high-speed move useful to get initiative'),
('CHUUNIN'::level, 'Unsealing technique', 'unseal what was sealed within a scroll'),
('JONIN'::level, 'Rasengan', 'All purpose physical attack, suited as 0HKO move'),
('JONIN'::level, 'Four flames formation', 'barrier jutsu that prevents any entry/exit from the barrier'),
('JONIN'::level, 'Barrier method formation', 'a barrier jutsu that makes explosive tags explode when target enters it'),
('JONIN'::level, 'Summmoning jutsu', 'Summons an ally for a given period of time. Requires blood contract'),
('KAGE'::level, 'Four Red Yang Formation', 'barrier jutsu that prevents any entry/exit from the barrier'),
('KAGE'::level, 'Summoning Jutsu: Reanimation', 'Summons the dead in exchange for a soul. Jutsu does not stop if user dies'),
('FORBIDDEN'::level, 'Shiki Fujin (Reaper Death Seal)', 'Sealing jutsu calling the Death God and claiming the user''s soul'),
('FORBIDDEN'::level, 'Kage bushin no jutsu', 'creates sentient clones of the user. equally diving chakra amongst all clones')
;