DROP TABLE IF EXISTS Arrow;
DROP TABLE IF EXISTS Equivalency;
DROP TABLE IF EXISTS ArcheryEnd;
DROP TABLE IF EXISTS ArcheryRange;
DROP TABLE IF EXISTS Score;
DROP TABLE IF EXISTS Competition;
DROP TABLE IF EXISTS Archer;
DROP TABLE IF EXISTS Round;
DROP TABLE IF EXISTS Class;
DROP TABLE IF EXISTS Equipment;

CREATE TABLE Equipment (
    EquipmentID INT AUTO_INCREMENT PRIMARY KEY,
    EquipmentName ENUM('Recurve', 'Compound', 'Recurve Barebow', 'Compound Barebow', 'Longbow') NOT NULL
);

CREATE TABLE Class(
ClassID INT AUTO_INCREMENT PRIMARY KEY,
ClassName VARCHAR(30) NOT NULL, /*ASSUMPTION: Must every class have a name? I say Yes, usually they have like... Male, Female*/
GENDER ENUM ('M', 'F') NOT NULL,
MinAge TINYINT UNSIGNED,
MaxAge TINYINT UNSIGNED,
CONSTRAINT CK_ValidAgeRange CHECK ((MinAge IS NULL OR MaxAge IS NULL) OR MaxAge >= MinAge)
);

CREATE TABLE Round(
RoundID INT AUTO_INCREMENT PRIMARY KEY,
RoundName VARCHAR(30) NOT NULL/*ASSUMPTION: Must every round have a name? I assume that they do... so you can tell World Archery rounds (styled like WA90/1440) from the Archery Australia specific ones like Long Sydney
ALSO, should there be numbers indicated the highest distance shot? and the max points? it's not really in the spec... well, it is, it shows the max points in one of the charts... but does the Club need it from this database???*/

);	

CREATE TABLE Archer(
ArcherID INT AUTO_INCREMENT PRIMARY KEY,

FirstName VARCHAR(30),/*ASSUMPTION: Must every archer have a first/lastname? Some cultures have only one name. Could check for First OR Last name?*/
LastName VARCHAR(30),
Gender ENUM ('M', 'F') NOT NULL,
DateOfBirth DATE NOT NULL,
DefaultEquipmentID INT,
CONSTRAINT FK_ArcherDefaultEquipment FOREIGN KEY (DefaultEquipmentID) REFERENCES Equipment (EquipmentID),
CONSTRAINT CK_ReasonableDOB CHECK (DateOfBirth > '1880-01-01')

);
/*, CONSTRAINT CK_ArcherHasName CHECK (FirstName IS NOT NULL OR LastName IS NOT NULL)*/

/* Gender IN ALL other FIELDS but archer could be a FOREIGN KEY so that an archer can't be in a class that's not their gender*/


CREATE TABLE Competition(
CompetitionID INT AUTO_INCREMENT PRIMARY KEY,
BaseRoundID INT NOT NULL,
CompetitionName VARCHAR(30), /*ASSUMPTION: Must every competition have a name? Maybe some compeititions only have types. 'Championship 2026'.*/
CompetitionDate DATE NOT NULL,
IsChampionship BOOL NOT NULL DEFAULT FALSE, /*default false because most are not championships i assume... not marked assumption cause it's not that serious*/
CONSTRAINT FK_CompetitionBaseRound FOREIGN KEY (BaseRoundID) REFERENCES Round (RoundID)
);

CREATE TABLE  Score(
ScoreID INT AUTO_INCREMENT PRIMARY KEY,
ArcherID INT NOT NULL,
RoundID INT NOT NULL,
EquipmentID INT NOT NULL,
ClassID INT NOT NULL,
CompetitionID INT,
ScoreDateTime DATETIME NOT NULL,
Status ENUM('STAGED', 'APPROVED', 'REJECTED') DEFAULT 'STAGED', /* ASSUMPTION: IMPORTANT: "rejected" doesnt appear in the brief. If this is our final database, add to confluence!*/
CONSTRAINT fkScoreArcher FOREIGN KEY (ArcherID)	REFERENCES Archer (ArcherID),
CONSTRAINT fkScoreRound	 FOREIGN KEY (RoundID)	REFERENCES Round (RoundID), /* ALL of these to the default "Restrict, Restrict" because scores are historical documents sooo yk*/
CONSTRAINT fkScoreEquipment  FOREIGN KEY (EquipmentID)   REFERENCES Equipment (EquipmentID),
CONSTRAINT fkScoreClass       FOREIGN KEY (ClassID)       REFERENCES Class (ClassID),
CONSTRAINT fkScoreCompetition FOREIGN KEY (CompetitionID) REFERENCES Competition (CompetitionID)
);


CREATE TABLE ArcheryRange(
ArcheryRangeID INT AUTO_INCREMENT PRIMARY KEY,
RoundID INT NOT NULL,
RangeNumber TINYINT UNSIGNED NOT NULL,
Distance TINYINT UNSIGNED NOT NULL, /*Could make ENUM? Could rename to DistanceMeters?*/
NumberOfEnds TINYINT UNSIGNED NOT NULL,
FaceSize ENUM('122cm', '120cm', '80cm', '60cm', '40cm') NOT NULL, /*A trigger will have to collapse 122cm and 120cm into the same thing somehow. Until I write that... this is the solution*/
CONSTRAINT UQ_RangeNumberInRound UNIQUE (RoundID, RangeNumber), /*Not sure abt this. I think I remember that it is necessary.*/
CONSTRAINT FK_RangeRound FOREIGN KEY (RoundID) REFERENCES Round (RoundID),
CONSTRAINT CK_ValidDistance CHECK (Distance IN (20, 30, 40, 50, 60, 70, 90)),
CONSTRAINT CK_ValidNumberOfEnds CHECK (NumberOfEnds IN (5, 6))
); /*should add before insert constraint that makes 122cm -> 120cm*/ 


CREATE TABLE ArcheryEnd (
  ArcheryEndID INT AUTO_INCREMENT PRIMARY KEY,
  ScoreID   INT NOT NULL,
  ArcheryRangeID   INT NOT NULL,
  EndNumber TINYINT UNSIGNED NOT NULL,
  CONSTRAINT UQ_EndPosition UNIQUE (ScoreID, ArcheryRangeID, EndNumber),
  CONSTRAINT FK_EndScore FOREIGN KEY (ScoreID) REFERENCES Score (ScoreID),
  CONSTRAINT FK_EndRange FOREIGN KEY (ArcheryRangeID) REFERENCES ArcheryRange (ArcheryRangeID),
  CONSTRAINT CK_ValidEndNumber CHECK (EndNumber BETWEEN 1 AND 6)
);

CREATE TABLE Equivalency(
BaseRoundID INT NOT NULL,
EquivRoundID INT NOT NULL,
ClassID INT NOT NULL,
EquipmentID INT NOT NULL,
ValidFrom DATE NOT NULL,
ValidTo DATE,

CONSTRAINT PRIMARY KEY (ClassID, EquipmentID, BaseRoundID, ValidFrom),
CONSTRAINT CK_ValidToMoreThanValidFrom CHECK (ValidTo >= ValidFrom OR ValidTo IS NULL),
CONSTRAINT FK_EquivalencyBaseRound FOREIGN KEY (BaseRoundID) REFERENCES  Round (RoundID),
CONSTRAINT FK_EquivalencyEquivRound FOREIGN KEY (EquivRoundID) REFERENCES Round (RoundID),
CONSTRAINT FK_EquivalencyClass FOREIGN KEY (ClassID) REFERENCES Class (ClassID),
CONSTRAINT FK_EquivalencyEquipment FOREIGN KEY (EquipmentID) REFERENCES Equipment (EquipmentID)
);

CREATE TABLE Arrow(
ArrowID INT AUTO_INCREMENT PRIMARY KEY,
ArcheryEndID INT NOT NULL,
ArrowNumber TINYINT UNSIGNED NOT NULL,
ArrowValue TINYINT UNSIGNED NOT NULL,
IsX BOOL NOT NULL DEFAULT FALSE, /*ASSUMPTION: IMPORTANT: Doesn't IsX imply ArrowValue = 10? Isn't this redundant? I need to check the spec & talk to teammates.*/


CONSTRAINT FK_ArrowEnd FOREIGN KEY (ArcheryEndID) REFERENCES ArcheryEnd (ArcheryEndID) ON UPDATE CASCADE ON DELETE CASCADE,
CONSTRAINT UQ_ArrowNumberInEnd UNIQUE (ArcheryEndID, ArrowNumber),
CONSTRAINT CK_ArrowValue CHECK (ArrowValue BETWEEN 0 AND 10),
CONSTRAINT CK_ArrowNumber CHECK (ArrowNumber BETWEEN 1 AND 6),
CONSTRAINT CK_ArrowXis10 CHECK ((IsX = TRUE AND ArrowValue = 10) OR IsX = FALSE) /*ASSUMPTION: IMPORTANT: Check in light of the earlier unsure assumption*/
);
/*need also trigger that ensures ArcheryEND range and score roundid is same*/