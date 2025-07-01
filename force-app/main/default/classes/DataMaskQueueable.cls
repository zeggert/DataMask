public with sharing class DataMaskQueueable implements Queueable, Database.AllowsCallouts {
    String query;

    public DataMaskQueueable(String query) {
        this.query = query;
    }

    public void execute(QueueableContext context) {
        //start batch job
        Database.executeBatch(new DataMaskBatch(query), 1000);
    }
}