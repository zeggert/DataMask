global class DataMaskGetQueriesBatch implements Database.Batchable<String> {
   
    Set<String> fieldTypesToMask;

    public DataMaskGetQueriesBatch(Set<String> fieldTypesToMask) {
        this.fieldTypesToMask = fieldTypesToMask;
    }

    global Iterable<String> start(Database.BatchableContext BC) {

        return DatamaskService.getSoqlQueryStrings(fieldTypesToMask);
    }

    global void execute(Database.BatchableContext BC, List<String> scope) {
        //enqueue job to start a sepearate batch job for each object to mask and update the records
        //batch size must be 1 because we can only enqueue one queueable job per transaction
        System.enqueueJob(new DataMaskQueueable(scope[0]));
    }

    global void finish(Database.BatchableContext BC) {

    }
}