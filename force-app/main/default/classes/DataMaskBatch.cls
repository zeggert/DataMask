global class DataMaskBatch implements Database.Batchable<sObject> {
   
    String query;

    public DataMaskBatch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        if(!scope.isEmpty()) {
            DataMaskService.maskData(scope, 'test');
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}