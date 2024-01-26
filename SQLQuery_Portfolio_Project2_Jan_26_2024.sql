/*
CLEANING DATA IN SQL 

*/

SELECT *
	FROM Nashville_Housing

------------------------------------------------------------------------------------------------------------
-- Standardize Date Format
-- We can remove SaleDate from the table at a later date

SELECT SaleDate
	FROM Nashville_Housing

SELECT SaleDate, CONVERT(Date, SaleDate) -- what we want the date to look like
	FROM Nashville_Housing

UPDATE Nashville_Housing
	SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE Nashville_Housing -- Adding a new column as the above did not work
	ADD SaleDateConverted Date

UPDATE Nashville_Housing
	SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
	FROM Nashville_Housing

------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

SELECT PropertyAddress
	FROM Nashville_Housing

SELECT PropertyAddress
	FROM Nashville_Housing
	WHERE PropertyAddress IS NULL

SELECT *
	FROM Nashville_Housing
	WHERE PropertyAddress IS NULL

SELECT NV.ParcelID, NV.PropertyAddress, NH.ParcelID, NH.PropertyAddress,
			ISNULL(NV.PropertyAddress, NH.PropertyAddress)
	FROM Nashville_Housing NV
		JOIN Nashville_Housing NH
		ON NV.ParcelID = NH.ParcelID
		AND NV.[UniqueID ] <> NH.[UniqueID ]
		WHERE NV.PropertyAddress IS NULL

-- IS NULL Returns the specified value IF the expression is NULL, otherwise returns the existing expression:

UPDATE NV
	SET PropertyAddress = ISNULL(NV.PropertyAddress, NH.PropertyAddress)
	FROM Nashville_Housing NV
		JOIN Nashville_Housing NH
		ON NV.ParcelID = NH.ParcelID
		AND NV.[UniqueID ] <> NH.[UniqueID ]
		WHERE NV.PropertyAddress IS NULL

------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress, ParcelID
	FROM Nashville_Housing
	ORDER BY ParcelID

-- The -1 is to avoid the comma, and the +1 is to get all values after the comma
-- Due to the addresses having different lengths, we use CHARINDEX to pin piont where we need to stop
-- SUBSTRING(string, start, length)
-- 1) string = propertyaddress; start = 1, length = charindex...
-- 2) string = propertyaddress; start = charindex, length = len...


SELECT 
		SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Adress,
		SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Adress
	FROM Nashville_Housing

ALTER TABLE Nashville_Housing 
	ADD PropertySplitAddress NVARCHAR(255)



UPDATE Nashville_Housing
	SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE Nashville_Housing 
	ADD PropertyCityAddress NVARCHAR(255)



UPDATE Nashville_Housing
	SET PropertyCityAddress = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- The columns are added at the end of the table like the SaleDateConverted column
SELECT *
	FROM Nashville_Housing



-- Working on splitting OwnerAddress (We have the address, the city and state)
-- USING PARSENAME useful for string with delimiters (periods '.')
-- PARSENAME starts selecting string from the end of the string, so it is up to you to right the order of things
SELECT OwnerAddress
	FROM Nashville_Housing
	--WHERE OwnerAddress IS NOT NULL

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM 
	Nashville_Housing


ALTER TABLE Nashville_Housing 
	ADD OwnerSplitAddress NVARCHAR(255)

UPDATE Nashville_Housing
	SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)



ALTER TABLE Nashville_Housing 
	ADD OwnerSplitCity NVARCHAR(255)

UPDATE Nashville_Housing
	SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)



ALTER TABLE Nashville_Housing 
	ADD OwnerSplitState NVARCHAR(255)

UPDATE Nashville_Housing
	SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)


SELECT *
	FROM Nashville_Housing
------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
	FROM Nashville_Housing
	GROUP BY SoldAsVacant
	ORDER BY 2

SELECT SoldAsVacant
,	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
		END
FROM Nashville_Housing


UPDATE Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
		END

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
	FROM Nashville_Housing
	GROUP BY SoldAsVacant
	ORDER BY 2


------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

SELECT *
	FROM Nashville_Housing


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER () OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) Row_Num
FROM Nashville_Housing
--ORDER BY ParcelID
)
DELETE --Replace DELETE WITH SELECT to check if any rows appear, if none, your work is done
FROM RowNumCTE
WHERE Row_Num > 1
--ORDER BY PropertyAddress



------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns 
-- It is not advisable to delete from the raw data in the database, maybe from created personal 'Views'


SELECT *
	FROM Nashville_Housing

ALTER TABLE Nashville_Housing
	DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

--ALTER TABLE Nashville_Housing
--	DROP COLUMN TaxDistrict


------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
