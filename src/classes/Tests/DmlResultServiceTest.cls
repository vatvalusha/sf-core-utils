@IsTest
private class DmlResultServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(
                    Name = 'Test Account ' + i
            ));
        }
        insert testAccounts;

        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact ' + i,
                    Email = 'test' + i + '@example.com'
            ));
        }
        insert testContacts;
    }


    @IsTest
    static void testBulkUpdate() {
        List<Contact> contactsToUpdate = [SELECT Id, LastName FROM Contact];
        for (Contact c : contactsToUpdate) {
            c.LastName = 'Updated ' + c.LastName;
        }

        Test.startTest();
        List<DmlResult> results = DmlResultService.bulkUpdate(contactsToUpdate);
        Test.stopTest();

        System.assertEquals(3, results.size());
        for (DmlResult result : results) {
            System.assertEquals(true, result.success);
            System.assertNotEquals(null, result.recordId);
            System.assertEquals(0, result.errors.size());
        }
    }

    @IsTest
    static void testBulkUpsert() {
        List<Contact> contactsToUpsert = [SELECT Id, LastName FROM Contact];
        for (Contact c : contactsToUpsert) {
            c.LastName = 'Upserted ' + c.LastName;
        }

        Test.startTest();
        List<DmlResult> results = DmlResultService.bulkUpsert(contactsToUpsert);
        Test.stopTest();

        System.assertEquals(3, results.size());
        for (DmlResult result : results) {
            System.assertEquals(true, result.success);
            System.assertNotEquals(null, result.recordId);
            System.assertEquals(0, result.errors.size());
        }
    }

    @IsTest
    static void testBulkDelete() {

        List<Contact> contactsToDelete = [SELECT Id FROM Contact LIMIT 2];

        Test.startTest();
        List<DmlResult> results = DmlResultService.bulkDelete(contactsToDelete);
        Test.stopTest();

        System.assertEquals(2, results.size());
        for (DmlResult result : results) {
            System.assertEquals(true, result.success);
            System.assertNotEquals(null, result.recordId);
            System.assertEquals(0, result.errors.size());
        }

        // Verify that the records are deleted
        List<Contact> remainingContacts = [SELECT Id FROM Contact];
        System.assertEquals(1, remainingContacts.size());
    }

    @IsTest
    static void testGetGenericErrorResultsSaveResult() {
        List<Account> accounts = new List<Account>{
                new Account(),
                new Account(Name = 'Valid Account')
        };
        List<Database.SaveResult> saveResults = Database.insert(accounts, false);

        Test.startTest();
        List<DmlResult> results = DmlResultService.getGenericErrorResults(saveResults);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return results for all failed records');

        Boolean hasFailure = false;
        for (DmlResult result : results) {
            if (!result.success) {
                hasFailure = true;
                System.assertEquals(1, result.errors.size(), 'Failed record should have error message');
            }
        }

        System.assert(hasFailure, 'Should have failure results');
    }

    @IsTest
    static void testGetGenericErrorResultsUpdateResult() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];

        for (Account acc : accounts) {
            acc.Name = null;
        }

        List<Database.UpsertResult> updateResult = Database.upsert(accounts, false);

        Test.startTest();
        List<DmlResult> results = DmlResultService.getGenericErrorResults(updateResult);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return results for all failed records');

        Boolean hasFailure = false;
        for (DmlResult result : results) {
            if (!result.success) {
                hasFailure = true;
                System.assertEquals(1, result.errors.size(), 'Failed record should have error message');
            }
        }

        System.assert(hasFailure, 'Should have failure results');
    }


    @IsTest
    static void testGetGenericErrorResultsDeleteResult() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];

        List<Database.DeleteResult> deleteResult = Database.delete(accounts, false);

        Test.startTest();
        List<DmlResult> results = DmlResultService.getGenericErrorResults(deleteResult);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return results for all failed records');
    }

    @IsTest
    static void testGetGenericErrorResultsEmptyInput() {
        Test.startTest();
        List<DmlResult> results = DmlResultService.getGenericErrorResults(new List<Object>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }

    @IsTest
    static void testGetGenericErrorResultsNullInput() {
        Test.startTest();
        List<DmlResult> results = DmlResultService.getGenericErrorResults(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }
}