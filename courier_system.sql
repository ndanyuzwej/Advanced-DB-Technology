1. Create Tables with Constraints
-- 1. Sender Table
CREATE TABLE Sender (
    SenderID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Address VARCHAR(255),
    Contact VARCHAR(15),
    City VARCHAR(50) NOT NULL
);

-- 2. Receiver Table
CREATE TABLE Receiver (
    ReceiverID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Address VARCHAR(255),
    City VARCHAR(50) NOT NULL,
    Phone VARCHAR(15)
);

-- 3. DeliveryAgent Table
CREATE TABLE DeliveryAgent (
    AgentID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Region VARCHAR(50),
    Phone VARCHAR(15),
    VehicleNo VARCHAR(20) UNIQUE
);

-- 4. Package Table (FKs to Sender, Receiver, Agent)
CREATE TABLE Package (
    PackageID SERIAL PRIMARY KEY,
    SenderID INT NOT NULL REFERENCES Sender(SenderID),
    ReceiverID INT NOT NULL REFERENCES Receiver(ReceiverID),
    Weight NUMERIC(5, 2) NOT NULL CHECK (Weight > 0),
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('Pending', 'In Transit', 'Delivered', 'Failed')),
    AgentID INT REFERENCES DeliveryAgent(AgentID)
);

-- 5. Route Table (FK to DeliveryAgent)
CREATE TABLE Route (
    RouteID SERIAL PRIMARY KEY,
    AgentID INT NOT NULL REFERENCES DeliveryAgent(AgentID),
    StartPoint VARCHAR(100) NOT NULL,
    EndPoint VARCHAR(100) NOT NULL,
    DistanceKM NUMERIC(6, 2) CHECK (DistanceKM > 0)
);

-- 6. Payment Table (FK to Package, includes CASCADE DELETE)
CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    PackageID INT UNIQUE NOT NULL, -- UNIQUE for 1:1 relationship with Package
    Amount NUMERIC(10, 2) NOT NULL CHECK (Amount > 0),
    Method VARCHAR(50),
    PaymentDate DATE NOT NULL,
    -- FK with CASCADE DELETE as requested in Task 2
    FOREIGN KEY (PackageID) REFERENCES Package(PackageID) ON DELETE CASCADE
);
----------------------------------------------------------------------------
2. Apply CASCADE DELETE from Package → Payment
FOREIGN KEY (PackageID) REFERENCES Package(PackageID) ON DELETE CASCADE
------------------------------------------------------------------------------
3. Insert Sample Records
-- Insert Sample Senders
INSERT INTO Sender (FullName, Address, Contact, City) VALUES
('Kwizera Jean', 'KG 567 St, Kicukiro', '0788123456', 'Kigali'),
('Mukamana Alice', 'NR 22 Ave, Nyarugenge', '0733654321', 'Kigali'),
('Uwera Divine', 'KN 12 Rd, Muhoza', '0783987654', 'Musanze'),
('Ndayishimiye Eric', 'RN 1 St, Tumba', '0722112233', 'Huye');

-- Insert Sample Receivers
INSERT INTO Receiver (FullName, Address, City, Phone) VALUES
('Habimana David', 'CH 45 Ave, Ngoma', 'Huye', '0785001122'),
('Cyiza Sandrine', 'RN 5 St, Gisenyi', 'Rubavu', '0735998877'),
('Gatete Ben', 'KK 30 Rd, Remera', 'Kigali', '0780445566'),
('Mugisha Claude', 'KN 8 St, Gasabo', 'Kigali', '0730776655');

-- Insert Sample Delivery Agents
INSERT INTO DeliveryAgent (FullName, Region, Phone, VehicleNo) VALUES
('Byiringiro Jean', 'Kigali Metro', '0788001002', 'RAA-501A'),
('Igiraneza Sonia', 'Northern Province', '0733909080', 'RAA-705B'),
('Mutesi Angel', 'Southern Province', '0722102030', 'RAC-210C');

-- Insert Sample Packages
-- Package 1: Delivered
-- Senders: 1.Kwizera, 2.Mukamana, 3.Uwera, 4.Ndayishimiye
-- Receivers: 1.Habimana, 2.Cyiza, 3.Gatete, 4.Mugisha
-- Agents: 1.Byiringiro, 2.Igiraneza, 3.Mutesi

INSERT INTO Package (SenderID, ReceiverID, Weight, Status, AgentID) VALUES
(1, 1, 2.5, 'Delivered', 3),     -- Kigali -> Huye (Mutesi)
(2, 2, 10.1, 'In Transit', 2),  -- Kigali -> Rubavu (Igiraneza)
(3, 3, 5.0, 'Pending', 1),      -- Musanze -> Kigali (Byiringiro)
(4, 4, 0.8, 'Delivered', 1),    -- Huye -> Kigali (Byiringiro)
(1, 2, 1.5, 'Pending', 2),      -- Kigali -> Rubavu (Igiraneza)
(2, 1, 3.2, 'In Transit', 3);   -- Kigali -> Huye (Mutesi)

-- Insert Sample Route (for Agent 1 and 2)
INSERT INTO Route (AgentID, StartPoint, EndPoint, DistanceKM) VALUES
(1, 'Kigali', 'Rwamagana', 60.0),
(2, 'Kigali', 'Musanze', 100.0),
(3, 'Kigali', 'Huye', 130.0),
(1, 'Kigali', 'Bugesera', 45.0),
(2, 'Musanze', 'Rubavu', 95.0);

-- Insert Sample Payment (for Delivered Package 1)
INSERT INTO Payment (PackageID, Amount, Method, PaymentDate) VALUES
(1, 5500.00, 'Mobile Money', CURRENT_DATE), -- Package 1: Delivered
(4, 2200.00, 'Cash', CURRENT_DATE);        -- Package 4: Delivered
-----------------------------------------------------------------------

4. Retrieve Delivered Packages

SELECT
    P.PackageID,
    P.Weight,
    S.FullName AS SenderName,
    S.City AS SenderCity,
    R.FullName AS ReceiverName,
    R.City AS ReceiverCity,
    DA.FullName AS DeliveryAgent
FROM
    Package P
JOIN
    Sender S ON P.SenderID = S.SenderID
JOIN
    Receiver R ON P.ReceiverID = R.ReceiverID
JOIN
    DeliveryAgent DA ON P.AgentID = DA.AgentID
WHERE
    P.Status = 'Delivered';
-------------------------------------------------

5. Update Package Status and Agent Performance
UPDATE Package
SET Status = 'Delivered'
WHERE PackageID = 2 AND Status != 'Delivered';


-------------------------------------------------------------------------------------------------
-- Retrieve agent performance (total 'Delivered' packages) for the agent who handled package ID 2
6. Identify Busiest Delivery Agent by Route Count

SELECT
    DA.FullName AS AgentName,
    COUNT(P.PackageID) AS TotalDeliveredPackages
FROM
    Package P
JOIN
    DeliveryAgent DA ON P.AgentID = DA.AgentID
WHERE
    P.Status = 'Delivered'
    AND DA.AgentID = (SELECT AgentID FROM Package WHERE PackageID = 2)
GROUP BY
    DA.FullName;

SELECT
    DA.FullName AS AgentName,
    DA.AgentID,
    COUNT(R.RouteID) AS TotalRoutes
FROM
    Route R
JOIN
    DeliveryAgent DA ON R.AgentID = DA.AgentID
GROUP BY
    DA.AgentID, DA.FullName
ORDER BY
    TotalRoutes DESC
LIMIT 1;
--------------------------------------------------

7. Create a View Showing Total Deliveries per City

CREATE VIEW V_TotalDeliveriesPerCity AS
SELECT
    R.City AS DeliveryCity,
    COUNT(P.PackageID) AS TotalDelivered
FROM
    Package P
JOIN
    Receiver R ON P.ReceiverID = R.ReceiverID
WHERE
    P.Status = 'Delivered'
GROUP BY
    R.City;

-- Example: Querying the new view
SELECT * FROM V_TotalDeliveriesPerCity;
-------------------------------------------------

Implement a Trigger for Pending Delivery Limit

This requires a Function (to define the logic) and a Trigger (to execute the function before an INSERT or UPDATE on the Package table).

a. Create the Trigger Function

CREATE OR REPLACE FUNCTION check_pending_delivery_limit()
RETURNS TRIGGER AS $$
DECLARE
    pending_count INT;
BEGIN
    -- Check if AgentID is being set or updated, and if the status is 'Pending'
    IF NEW.AgentID IS NOT NULL AND NEW.Status = 'Pending' THEN
        -- Count existing 'Pending' packages for the agent
        SELECT COUNT(*)
        INTO pending_count
        FROM Package
        WHERE AgentID = NEW.AgentID AND Status = 'Pending'
        -- Exclude the current package if it's an UPDATE
        AND (TG_OP = 'INSERT' OR PackageID != NEW.PackageID);

        -- Check the limit (5 pending deliveries)
        IF pending_count >= 5 THEN
            RAISE EXCEPTION 'Agent % (ID: %) cannot be assigned. They already have % pending deliveries (Max 5).',
                (SELECT FullName FROM DeliveryAgent WHERE AgentID = NEW.AgentID),
                NEW.AgentID,
                pending_count;
        END IF;
    END IF;

    -- Allow the operation to proceed
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------
b. Create the Trigger

CREATE TRIGGER TR_CheckAgentCapacity
BEFORE INSERT OR UPDATE OF AgentID, Status ON Package
FOR EACH ROW
EXECUTE FUNCTION check_pending_delivery_limit();