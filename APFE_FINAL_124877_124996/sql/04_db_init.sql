-- ******************************************************
-- 04_db_init.sql: INSERTS DE DADOS INICIAIS
-- ******************************************************

-- 1. Circuito
INSERT INTO Circuito (Nome, Cidade, Pais, Comprimento_km, NumCurvas) VALUES
('Autódromo Internacional do Algarve', 'Portimão', 'Portugal', 4.653, 15),
('Circuit de Barcelona-Catalunya', 'Montmeló', 'Espanha', 4.675, 16);

-- 2. Equipa
INSERT INTO Equipa (Nome, Nacionalidade, Base, ChefeEquipa, AnoEstreia, ModeloChassis, Power_Unit, PilotosReserva) VALUES
('Mercedes-AMG PETRONAS F1 Team', 'Alemã', 'Brackley', 'Toto Wolff', 2010, 'W16', 'Mercedes', 2),
('Oracle Red Bull Racing', 'Austríaca', 'Milton Keynes', 'Christian Horner', 2005, 'RB21', 'Honda RBPT', 1);

-- 3. Membros da Equipa (Membros de suporte e pilotos)
INSERT INTO Membros_da_Equipa (Nome, Nacionalidade, DataNascimento, Género, Função, ID_Equipa) VALUES
('Lewis Hamilton', 'Britânica', '1985-01-07', 'M', 'Piloto', 1),   -- ID_Membro 1
('George Russell', 'Britânica', '1998-02-15', 'M', 'Piloto', 1),   -- ID_Membro 2
('Max Verstappen', 'Holandesa', '1997-09-30', 'M', 'Piloto', 2),   -- ID_Membro 3
('Sergio Pérez', 'Mexicana', '1990-01-26', 'M', 'Piloto', 2);     -- ID_Membro 4

-- 4. Piloto
INSERT INTO Piloto (NumeroPermanente, Abreviação, ID_Equipa, ID_Membro) VALUES
(44, 'HAM', 1, 1),
(63, 'RUS', 1, 2),
(1, 'VER', 2, 3),
(11, 'PER', 2, 4);

-- 5. Contrato (Apenas 1 por Piloto/Membro para simplificar)
INSERT INTO Contrato (AnoInicio, AnoFim, Função, Salário, Género, ID_Membro) VALUES
(2025, 2027, 'Piloto', 40000000.00, 'M', 1);

-- 6. Temporada
INSERT INTO Temporada (Ano, NumCorridas, PontosPiloto, PontosEquipa, PosiçãoPiloto, PosiçãoEquipa) VALUES
(2025, 24, 0, 0, NULL, NULL);

-- 7. Grande_Prémio
INSERT INTO Grande_Prémio (NomeGP, DataCorrida, NumeroVoltas, ID_Circuito, Ano_Temporada) VALUES
('GP de Portugal', '2025-05-04', 66, 1, 2025);

-- 8. Sessões
INSERT INTO Sessões (NomeSessão, Estado, CondiçõesPista, NomeGP) VALUES
('Qualificação GP Portugal', 'Concluída', 'Seco', 'GP de Portugal'),
('Corrida GP Portugal', 'Concluída', 'Seco', 'GP de Portugal');

-- 9. Resultados (A inserção aciona a TRIGGER)
EXEC dbo.RegistarResultado 'Corrida GP Portugal', 'VER', 1, 1, '01:34:00', 'Finished', 25.0;
EXEC dbo.RegistarResultado 'Corrida GP Portugal', 'HAM', 2, 2, '01:34:10', 'Finished', 18.0;
EXEC dbo.RegistarResultado 'Corrida GP Portugal', 'PER', 3, 3, '01:34:25', 'Finished', 15.0;
EXEC dbo.RegistarResultado 'Corrida GP Portugal', 'RUS', 4, 18, '01:40:00', 'DNF', 0.0;

-- 10. Penalizações
INSERT INTO Penalizações (TipoPenalização, Motivo, NomeSessão, ID_Piloto) VALUES
('10 segundos', 'Falsa partida', 'Corrida GP Portugal', 4); -- Piloto PER (ID 4)

-- 11. Pitstop
EXEC dbo.RegistarPitstop 'Corrida GP Portugal', 'VER', 20, '00:00:02.500', '00:00:22.000';
EXEC dbo.RegistarPitstop 'Corrida GP Portugal', 'HAM', 21, '00:00:02.300', '00:00:21.500';