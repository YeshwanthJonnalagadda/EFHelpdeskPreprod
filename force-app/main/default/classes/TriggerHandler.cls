public virtual class TriggerHandler {
    protected virtual void beforeInsert(){
        System.debug('Before Insert');
    }
    protected virtual void afterInsert(){
        System.debug('After Insert');
    }
    protected virtual void beforeUpdate(){
        System.debug('Before Update');
    }
    protected virtual void afterUpdate(){
        System.debug('After Update');
    }
    protected virtual void beforeDelete(){
        System.debug('Before Delete');
    }
    protected virtual void afterDelete(){
        System.debug('After Delete');
    }
    protected virtual void afterUndelete(){
        System.debug('After Undelete');
    }

    protected TriggerContext context;

    //constructor
    public TriggerHandler(){
        this.setTriggerContext();
    }

    public void run() {
        switch on context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    public void setTriggerContext(){
        if(Trigger.isExecuting)
        this.setTriggerContext(null, false);
    }

    @TestVisible
    public void setTriggerContext(String cxt, Boolean testMode){
        if((!testMode && Trigger.isbefore && Trigger.isinsert) || (testMode && cxt <> Null && cxt == 'BEFORE_INSERT')){
            this.context = TriggerContext.BEFORE_INSERT;
        }
        if((!testMode && Trigger.isafter && Trigger.isinsert) || (testMode && cxt <> Null && cxt == 'AFTER_INSERT')){
            this.context = TriggerContext.AFTER_INSERT;
        }
        if((!testMode && Trigger.isbefore && Trigger.isupdate) || (testMode && cxt <> Null && cxt == 'BEFORE_UPDATE')){
            this.context = TriggerContext.BEFORE_UPDATE;
        }
        if((!testMode && Trigger.isafter && Trigger.isupdate) || (testMode && cxt <> Null && cxt == 'AFTER_UPDATE')){
            this.context = TriggerContext.AFTER_UPDATE;
        }
        if((!testMode && Trigger.isbefore && Trigger.isdelete) || (testMode && cxt <> Null && cxt == 'BEFORE_DELETE')){
            this.context = TriggerContext.BEFORE_DELETE;
        }
        if((!testMode && Trigger.isafter && Trigger.isdelete) || (testMode && cxt <> Null && cxt == 'AFTER_DELETE')){
            this.context = TriggerContext.AFTER_DELETE;
        }
        if((!testMode && Trigger.isafter && Trigger.isundelete) || (testMode && cxt <> Null && cxt == 'AFTER_UNDELETE')){
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    public Enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }
}