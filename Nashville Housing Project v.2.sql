--Data Cleaning/Formatting

--Update Sale Date to date instead of datetime format
SELECT SaleDate
FROM dbo.[Nashville Housing]

UPDATE [Nashville Housing]
SET SaleDate = CONVERT(date, SaleDate)


--Find Null Property Addresses and Replace with address for same Parcel ID
SELECT *
FROM dbo.[Nashville Housing]
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.[Nashville Housing] a
JOIN dbo.[Nashville Housing] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.[Nashville Housing] a
JOIN dbo.[Nashville Housing] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


--Break out Address into multiple columns

SELECT TOP 100 PropertyAddress
FROM dbo.[Nashville Housing]

SELECT TOP 100 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS 'Street Address',
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2,LEN(PropertyAddress)) AS 'City'
FROM dbo.[Nashville Housing]

ALTER TABLE [Nashville Housing]
Add StreetAddress NVARCHAR(255);

UPDATE [Nashville Housing]
SET StreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE [Nashville Housing]
Add City NVARCHAR(255);

UPDATE [Nashville Housing]
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2,LEN(PropertyAddress))

SELECT PropertyAddress, StreetAddress, City
FROM dbo.[Nashville Housing]


--Reformat Owner Address
SELECT 
	PARSENAME(REPLACE(OwnerAddress,',', '.'), 3) AS 'OwnerStreet',
	PARSENAME(REPLACE(OwnerAddress,',', '.'), 2) AS 'OwnerCity',
	PARSENAME(REPLACE(OwnerAddress,',', '.'), 1) AS 'OwnerState'
FROM dbo.[Nashville Housing]

ALTER TABLE [Nashville Housing]
Add OwnerStreet NVARCHAR(255);

UPDATE [Nashville Housing]
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

ALTER TABLE [Nashville Housing]
Add OwnerCity NVARCHAR(255);

UPDATE [Nashville Housing]
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

ALTER TABLE [Nashville Housing]
Add OwnerState NVARCHAR(255);

UPDATE [Nashville Housing]
SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

SELECT OwnerStreet, OwnerCity, OwnerState
FROM dbo.[Nashville Housing]


--Change 1 and 0 to Yes and No in "Sold as Vacant" field

SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 1 THEN 'Yes'
		WHEN SoldAsVacant = 0 THEN 'No'
	END AS 
FROM dbo.[Nashville Housing]

ALTER TABLE [Nashville Housing]
ALTER COLUMN SoldAsVacant NVARCHAR(50);

UPDATE [Nashville Housing]
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 1 THEN 'Yes'
		WHEN SoldAsVacant = 0 THEN 'No'
		END

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM dbo.[Nashville Housing]
GROUP BY SoldAsVacant


--Remove Duplicates

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress, 
				 SalePrice, 
				 SaleDate, 
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
FROM dbo.[Nashville Housing])

SELECT *  
FROM RowNumCTE
WHERE row_num > 1


--Delete Unused Columns

ALTER TABLE dbo.[Nashville Housing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress