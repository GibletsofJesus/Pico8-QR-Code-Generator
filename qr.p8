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

 --let's also go with the L error correction level (15% of data can be lost and still readable)
 local dataSize = #dataToEncode * 1.07
 local version = findMinimumQrCodeVersionRequiredForLLevelErrorCorrectionOfAlphanumericData(dataSize)

 local encodedData = encodeDataAsBinaryString(dataToEncode, version)

 local messagePolynomial={}
 for i=1,#encodedData,8 do
  ?tonum("0b"..sub(encodedData,i,i+7))
  add(messagePolynomial,tonum("0b"..sub(encodedData,i,i+7)))
 end
 --instead of generating the error correction polynomials
 -- we'll instead fetch the results from a list since maths is hard and life's too short
 errorCorrectionPolynomial = getPreGeneratedPolynomialForErrorCorrectionLevelLForVersion(version)
 ?errorCorrectionPolynomial
 ?version

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

function findMinimumQrCodeVersionRequiredForLLevelErrorCorrectionOfAlphanumericData(dataSize)
 --values here going from version 1 to 9
 local upperLimits={25,47,77,114,154,195,224,279,335}
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

--For L Error Correction level
function findTotalNumberOfDataCodewordsForVersion(version)
 local valuesForMediumErrorCorrection={19,34,55,80,108,136,156,194,232}
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

function getPreGeneratedPolynomialForErrorCorrectionLevelLForVersion(version)
 --get codewords required for group 1
 local errorCorrectionCodeWordsForGroup1={7,10,15,20,26,18,20,24,30}
 local numberOfBlocksRequiredInGroup1={1,1,1,1,1,2,2,2,2}
 local preGeneratedPolynomialForErrorCorrectionLevelL={
  {0,87,229,146,149,238,102,21},
  {0,251,67,46,61,118,70,64,94,32,45},
  {0,8,183,61,91,202,37,51,58,58,237,140,124,5,99,105}
 }
 return preGeneratedPolynomialForErrorCorrectionLevelL[version]
end

--makeQRCode(tweet_url)
makeQRCode("craigtinney.co.uk")
--makeQRCode("http://craigtinney.co.uk/carts/games/helicopter.html")
