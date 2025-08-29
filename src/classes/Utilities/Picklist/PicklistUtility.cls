public with sharing class PicklistUtility {

    public static Map<String, List<PicklistOption>> getDependentOptions(String sobjectName, String targetField, String controlledField) {

        List<Schema.PicklistEntry> targetPLOptions = getField(sobjectName, targetField)
                .getDescribe()
                .getPicklistValues();

        List<Schema.PicklistEntry> controllerPLOptions = getField(sobjectName, controlledField)
                .getDescribe()
                .getPicklistValues();

        List<PicklistOption> options = PicklistUtility.wrapPicklistEntries(targetPLOptions);

        return getDependentOptions(options, controllerPLOptions);
    }

    private static Schema.SObjectField getField(String sobjectName, String field) {
        return Schema.getGlobalDescribe()
                .get(sobjectName)
                .getDescribe()
                .fields
                .getMap()
                .get(field);
    }

    public static Map<String, List<PicklistOption>> getDependentOptions(List<PicklistOption> options, List<Schema.PicklistEntry> controllerOptions) {

        Map<String, List<PicklistOption>> results = new Map<String, List<PicklistOption>>();
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry item : controllerOptions) {
            String value = item.getValue();
            results.put(value, new List<PicklistOption>{
//                    new PicklistOption('None', null)
            });
            controllingValues.add(value);
        }

        for (PicklistOption item : options) {
            if (!Boolean.valueOf(item.active)) {
                continue;
            }
            String validForBits = base64ToBits(item.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    results.get(controllingValues.get(i)).add(item);
                }
            }
        }

        return results;
    }

    public static String decimalToBinary(Integer value) {
        String bits = '';
        while (value > 0) {
            Integer remainder = Math.mod(value, 2);
            value = Integer.valueOf(Math.floor(value / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }


    private static final String base64Chars = '' +
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
            'abcdefghijklmnopqrstuvwxyz' +
            '0123456789+/';


    private static List<PicklistOption> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistOption>)
                JSON.deserialize(JSON.serialize(PLEs), List<PicklistOption>.class);
    }

    public class PicklistOption {
        @AuraEnabled
        public String active { get; set; }
        @AuraEnabled
        public String defaultValue { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; } public String validFor { get; set; }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}