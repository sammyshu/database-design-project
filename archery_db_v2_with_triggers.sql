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
CompetitionID INT, /*ASSUMPTION: IMPORTANT: In the brief: "Archers shoot 6 arrows at a time, then move to collect them. 6 arrows are called an ’end’. If an
archer shoots 6 ends at a distance, they can record this as a ’score’ to see how they performed.
Fewer than 6 ends cannot be recorded.
Archers can shoot competitions, where a defined ’round’ is shot. The round can consist of one or
more distances and have ’ranges’ of 5 or 6 ends. For example, a WA (= World Archery) 900 round
has 5 ends at 60m, 5 ends at 50m and 5 ends at 40m. Hence it consists of 3 ranges. A WA720
consists of 2 ranges: Both ranges are 6 ends at 70m. Rounds have 2 – 4 ranges, but there are old
rounds that are not limited to four."

Now... this is very confusing. It first says fewer than six ends cannot be recorderd, but then it says that
a round can consist of one or more distances and have ranges of 5 or 6 ends. 
So... does this mean that a score can be recorded with fewer than 6 ends if the round is defined to have fewer than 6 ends? 


It seems that... if a score is recorded for a round, it must be associated with a competition...? And 
Or, interpretation 2, that the score ALWAYS has a round, but if that round has less than 6 ends, it MUST be part of a competition?


In our Confluence: "Each score is linked to a specific archer and round. The equipment and class associated with that score are recorded so historical results remain accurate."
If our Confluence is to be believed, then the score ALWAYS has a round, as stated in interpretation 2.

Regardless, competitionID is nullable.

I will add a trigger that allows a score's range to have less than 6 ends ONLY IF it  has a competitionID. Because apparently, if my interpretation of this document is correct, a NON-competition score MUST have 6 ends and not less nor more.

This must be added to our Confluence's  "Assumptions" section.*/


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
ArrowNumber TINYINT UNSIGNED NOT NULL,/*ASSUMPTION: IMPORTANT: Possible contradiction with brief. "Within an end, arrows are always recorded highest to lowest arrow score, so there is no need
to keep track of the order in which the arrows were shot in each end." Does this mean we should not keep track of the EndNumber? This was initially interpreted to be a constraint of the database, but it seems that they intended it to be the opposite of a constraint, actually something that we explicitly SHOULD NOT consider. Hmm... I could make this DEFAULT 255 or DEFAULT 0 and add a BEFORE INSERT trigger that automatically sets it to be the current lowest value - 1 so that we can have some number keeping track without giving the client the burden of having to keep track themselves... 
We should probably totally remove arrownumber?? */
ArrowValue TINYINT UNSIGNED NOT NULL,
IsX BOOL NOT NULL DEFAULT FALSE, /*ASSUMPTION: IMPORTANT: Doesn't IsX imply ArrowValue = 10? Isn't this redundant? I need to check the spec & talk to teammates.*/


CONSTRAINT FK_ArrowEnd FOREIGN KEY (ArcheryEndID) REFERENCES ArcheryEnd (ArcheryEndID) ON UPDATE CASCADE ON DELETE CASCADE,
CONSTRAINT UQ_ArrowNumberInEnd UNIQUE (ArcheryEndID, ArrowNumber),
CONSTRAINT CK_ArrowValue CHECK (ArrowValue BETWEEN 0 AND 10),
CONSTRAINT CK_ArrowNumber CHECK (ArrowNumber BETWEEN 1 AND 6),
CONSTRAINT CK_ArrowXis10 CHECK ((IsX = TRUE AND ArrowValue = 10) OR IsX = FALSE) /*ASSUMPTION: IMPORTANT: Check in light of the earlier unsure assumption*/
);
/*need also trigger that ensures ArcheryEND range and score roundid is same*/


DROP TRIGGER IF EXISTS TR_ArcheryRangeFaceSizeCollapseBeforeInsert;
DROP TRIGGER IF EXISTS TR_ArcheryRangeFaceSizeCollapseBeforeUpdate;
DROP TRIGGER IF EXISTS TR_ArcheryEndRangeRoundConsistency;
DROP TRIGGER IF EXISTS TR_ScoreEndsNumberBeforeInsert;
DROP TRIGGER IF EXISTS TR_ScoreEndsNumberBeforeUpdate;
DROP TRIGGER IF EXISTS TR_ArcheryEndNumberWithinRange;

DELIMITER //
CREATE TRIGGER TR_ArcheryRangeFaceSizeCollapseBeforeInsert BEFORE INSERT ON ArcheryRange /*Max name is 64 characters, this is 43... pushing it but its fine*/
FOR EACH ROW
BEGIN
    IF NEW.FaceSize = '122cm' THEN
        SET NEW.FaceSize = '120cm';
    END IF;
END//
DELIMITER ;
/*ASSUMPTION: NOTE: The specification states that FaceSize 120cm is the valid size, but Archery Australia itself uses 122cm. In confluence we addressed this.*/

DELIMITER //
CREATE TRIGGER TR_ArcheryRangeFaceSizeCollapseBeforeUpdate BEFORE UPDATE ON ArcheryRange
FOR EACH ROW
BEGIN
    IF OLD.FaceSize = '120cm' AND NEW.FaceSize = '122cm' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FaceSize 120cm and 122cm are considered equivalent. Please use 120cm.';
    END IF;
    IF OLD.FaceSize != '120cm' AND NEW.FaceSize = '122cm' THEN 
        SET NEW.FaceSize = '120cm';
    END IF;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER TR_ArcheryEndRangeRoundConsistency BEFORE INSERT ON ArcheryEnd
FOR EACH ROW
BEGIN
    
    DECLARE RangeRoundID INT;
    DECLARE ScoreRoundID INT;

    SELECT RoundID INTO RangeRoundID FROM ArcheryRange r WHERE r.ArcheryRangeID = NEW.ArcheryRangeID;
    SELECT RoundID INTO ScoreRoundID FROM Score s WHERE s.ScoreID = NEW.ScoreID;

    IF RangeRoundID != ScoreRoundID THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "ArcheryEnd's ArcheryRange and Score RoundIDs must match.";
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER TR_ScoreEndsNumberBeforeInsert BEFORE INSERT ON Score
FOR EACH ROW
BEGIN
    DECLARE TotalRanges INT; 
    DECLARE NonSixEndRanges INT;

    IF NEW.CompetitionID IS NULL THEN
        SELECT COUNT(*) INTO TotalRanges FROM ArcheryRange r WHERE r.RoundID = NEW.RoundID; /*all the ranges for this round... SHOULD BE ONE since its not a competition (read comment below)*/

        SELECT COUNT(*) INTO NonSixEndRanges FROM ArcheryRange r WHERE r.RoundID = NEW.RoundID AND r.NumberOfEnds != 6;

        IF TotalRanges != 1 OR NonSixEndRanges > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Scores without a competition must have a single round with a range of 6 ends only.';
        END IF;
    END IF;
END//
DELIMITER ;
/*ASSUMPTION: Check what the comment inside the Score table next to CompetitionID says. Also, a practice round can only have one range.
 This is because "If an
archer shoots 6 ends at a distance, they can record this as a ’score’". It says "A DISTANCE". Like one distance.*/


DELIMITER //
CREATE TRIGGER TR_ScoreEndsNumberBeforeUpdate BEFORE UPDATE ON Score
FOR EACH ROW
BEGIN
    DECLARE TotalRanges INT; 
    DECLARE NonSixEndRanges INT;

    IF NEW.CompetitionID IS NULL THEN
        SELECT COUNT(*) INTO TotalRanges FROM ArcheryRange r WHERE r.RoundID = NEW.RoundID; /*all the ranges for this round... SHOULD BE ONE since its not a competition (read comment below)*/
        SELECT COUNT(*) INTO NonSixEndRanges FROM ArcheryRange r WHERE r.RoundID = NEW.RoundID AND r.NumberOfEnds != 6;

        IF TotalRanges != 1 OR NonSixEndRanges > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Scores without a competition must have a single round with a range of 6 ends only.';
        END IF;
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER TR_ArcheryEndNumberWithinRange BEFORE INSERT ON ArcheryEnd
FOR EACH ROW
BEGIN
    DECLARE MaxEnds TINYINT UNSIGNED;
    SELECT NumberOfEnds INTO MaxEnds FROM ArcheryRange r WHERE r.ArcheryRangeID = NEW.ArcheryRangeID;
    IF NEW.EndNumber > MaxEnds THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EndNumber exceeds the number of ends defined for this range.';
    END IF;
END//
DELIMITER ;