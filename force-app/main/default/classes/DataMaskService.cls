public class DataMaskService {

    private static final Set<String> sObjectExclusions = new Set<String>{'User'};
    // Create a list of SOQL strings. To make this work we need to loop through these queries in a batch job. That batch job will then enqueue a queuable class. The queueable class will then start another batch job to 
    public static List<String> getSoqlQueryStrings(Set<String> fieldTypes){
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<String> soqlStringList = new List<String>();

        for (String objectName : globalDescribe.keySet()) {

            if(sObjectExclusions.contains(objectName)) {
                continue;
            }

            Schema.SObjectType sobjectType = globalDescribe.get(objectName);
            Schema.DescribeSObjectResult describe = sobjectType.getDescribe();

            if (!describe.isQueryable() || !describe.isUpdateable() || describe.isCustomSetting()) {
                continue;
            }

            Map<String, Schema.SObjectField> fields = describe.fields.getMap();
            List<String> fieldsToQuery = new List<String>();

            for (String fieldName : fields.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();

                // Skip system fields
                if (!fieldDescribe.isUpdateable() || fieldDescribe.isCalculated()) {
                    continue;
                }

                if (fieldTypes.contains('Email') && fieldDescribe.getType() == Schema.DisplayType.Email ||
                    fieldTypes.contains('Phone') && fieldDescribe.getType() == Schema.DisplayType.Phone ||
                    fieldTypes.contains('Address') && isAddressComponent(fieldName, fieldDescribe.getType())) {
                    fieldsToQuery.add(fieldName);
                }
            }

            if (fieldsToQuery.isEmpty()) {
                continue;
            }

            String soql = 'SELECT Id, ' + String.join(fieldsToQuery, ', ') + ' FROM ' + objectName + ' WHERE Id != null';
            soqlStringList.add(soql);
        }

        return soqlStringList;
    }

    private static Boolean isAddressComponent(String fieldName, Schema.DisplayType type) {
        //Set<String> addressParts = new Set<String>{'Street', 'City', 'State', 'PostalCode', 'Country'};
        Set<String> addressParts = new Set<String>{'Street'};
        for (String part : addressParts) {
            if (fieldName.toLowerCase().contains(part.toLowerCase()) && type == Schema.DisplayType.String) {
                return true;
            }
        }
        return false;
    }

    //every record in the list must be of the same type 
    public static void maskData(List<sObject> records, String maskingString) {
        List<SObject> recordsToUpdate = new List<SObject>();
        //get sObject describe from record id
        Schema.DescribeSObjectResult sObjectDescribe = records[0].Id.getSObjectType().getDescribe();
        String objectName = sObjectDescribe.name;
        Map<String, Schema.SObjectField> fields = sObjectDescribe.fields.getMap();

        for (SObject record : records) {
            Boolean changed = false;
            Map<String, Object> fieldsToValue = record.getPopulatedFieldsAsMap();

            for (String fieldName : fieldsToValue.keySet()){
                Schema.DisplayType fieldType = fields.get(fieldName).getDescribe().getType();
                String fieldValue = String.valueOf(record.get(fieldName));
                if (fieldType == Schema.DisplayType.Email) {
                    record.put(fieldName, fieldValue + '.' + maskingString);
                    changed = true;
                } else if (fieldType == Schema.DisplayType.Phone) {
                    record.put(fieldName, fieldValue.replaceFirst('(?<=^\\+?1[\\s\\-\\(]*)\\d{3}', '555'));
                    changed = true;
                } else if (isAddressComponent(fieldName, fieldType)) {
                    record.put(fieldName, 'Masked');
                    changed = true;
                }
            }

            if (changed) {
                recordsToUpdate.add(record);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            try {
                //update recordsToUpdate;
                System.debug(LoggingLevel.ERROR, 'Masked ' + recordsToUpdate.size() + ' records in ' + objectName);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error updating ' + objectName + ': ' + e.getMessage());
            }
        }
    }    
}