pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--https://www.thonky.com/qr-code-tutorial

tweet_url=
"https://twitter.com/intent/tweettexti%20just%20played%20this%20great%20%23pico8%20game%0come%20check%20it%20out%3A%0Ahttps%3A%2F%2Fwww.lexaloffle.com%2Fbbs%2F%3Ftid%3D31506"
--"https://twitter.com/intent/tweet?text=I%20just%20played%20this%20great%20%23Pico8%20game!%0ACome%20check%20it%20out%3A%0Ahttps%3A%2F%2Fwww.lexaloffle.com%2Fbbs%2F%3Ftid%3D31506&=&=undefined&"
-------------------------------helpers------------------------------------------

function integerToBinary(binaryValue,totalBits)
  --Source https://www.lexaloffle.com/bbs/?tid=27657
  local result,a="",0
  for i = 0,totalBits-1 do
   result=band(2^i,binaryValue)/2^i..result
  end
  return result
end

function getAlphanumericCharacterValue(character)
 if (character=="") return 0
 local values="0123456789abcdefghijklmnopqrstuvwxyz $%*+-./:"
 local result=1
 while character != sub(values,result,result) do
  result+=1
 end
 return result-1
end

 --------------------------QR code functions------------------------------------

function makeQRCode(dataToEncode)
 --lets use alphanumeric encoding since we're working with URLS
 --    WRONG DUMMY, can't have ? or caps which rules out youtube URLs for a start

 --let's also go with the M error correction level (15% of data can be lost and still readable)
 local dataSize = #dataToEncode * 1.15
 local version = findMinimumQrCodeVersionRequiredForMLevelErrorCorrectionOfAlphanumericData(dataSize)

 local encodedData = encodeDataAsBinaryString(dataToEncode, version)
 --output encoded data as chunks of 8 bits
 for i=1,#encodedData,16 do
  ?sub(encodedData,i,i+7) .. " " .. sub(encodedData,i+8,i+15)
 end

 for i=1,#encodedData,16 do
  ?tonum("0b"..sub(encodedData,i,i+7)) .. "           " .. tonum("0b"..sub(encodedData,i+8,i+15))
 end

 --Oh fucking buddy.
-- time to generate some fucking nonsense

end

function encodeDataAsBinaryString(dataToEncode, version)
 local modeIndicator = "0010"
 local originalInputLengthInBinary = integerToBinary(#dataToEncode,9)
 local encodedData = modeIndicator..originalInputLengthInBinary..encodeAlphaNumericStringToBinary(dataToEncode)

 local requiredDataLength = findTotalNumberOfDataCodewordsForVersion(version)*8
 local paddingRequired = requiredDataLength - #encodedData
 if paddingRequired>15 then
  encodedData=encodedData.."0000"
 else
  encodedData=encodedData..integerToBinary(paddingRequired)
 end

 local additionalPaddingRequiredToMakeEncodedDataLengthAMultipleOf8=#encodedData%8
 if additionalPaddingRequiredToMakeEncodedDataLengthAMultipleOf8!=0 then
  for i=0,7-additionalPaddingRequiredToMakeEncodedDataLengthAMultipleOf8 do
   encodedData=encodedData.."0"
  end
 end

 local bool236or17=true
 while #encodedData < requiredDataLength do
  if (bool236or17) encodedData=encodedData.."11101100"--236
  if (not bool236or17) encodedData=encodedData.."00010001"--17
  bool236or17=not bool236or17
 end

 return encodedData
end

function findMinimumQrCodeVersionRequiredForMLevelErrorCorrectionOfAlphanumericData(dataSize)
 --values here going from version 1 to 9
 local upperLimits={20,38,61,90,122,154,178,221,262}
 local optimalVersion=1

 if dataSize > upperLimits[#upperLimits] then
  ?"data is too big!"
  return
 end

 while dataSize > upperLimits[optimalVersion]do
  optimalVersion+=1
 end
 return optimalVersion
end

--For M Error Correction level
function findTotalNumberOfDataCodewordsForVersion(version)
 local valuesForMediumErrorCorrection={16,28,44,64,86,108,124,154,182}
 return valuesForMediumErrorCorrection[version]
end

function encodeAlphaNumericStringToBinary(dataToEncode)
 local encodedData=""
 for i=1,#dataToEncode,2 do
  local firstCharacterToBeEncoded = sub(dataToEncode,i,i)
  local secondCharacterToBeEncoded = sub(dataToEncode,i+1,i+1)
  if (secondCharacterToBeEncoded=="") then
   --encode final character as 6 bit binary string
   encodedData=encodedData..integerToBinary(getAlphanumericCharacterValue(firstCharacterToBeEncoded),6)
  else
   local twoCharactersToBeConvertedToBinary=
          getAlphanumericCharacterValue(firstCharacterToBeEncoded)*45
          + getAlphanumericCharacterValue(secondCharacterToBeEncoded)
   encodedData=encodedData..integerToBinary(twoCharactersToBeConvertedToBinary,11)
  end
 end
 return encodedData
end

--makeQRCode(tweet_url)
makeQRCode("craigtinney.co.uk")
--makeQRCode("http://craigtinney.co.uk/carts/games/helicopter.html")
