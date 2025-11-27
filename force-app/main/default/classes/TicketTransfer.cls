public class TicketTransfer {
    @InvocableMethod(label='TransferToFreshservice' callout = true)

    public static List<Integer> transfer(List<TicketTransferFields> fields){

        List<Integer> statusCodes = new List<Integer>();

        for(TicketTransferFields eachTTF: fields){
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('email', eachTTF.email);
            gen.writeNumberField('group_id', eachTTF.groupId);
            gen.writeNumberField('priority', eachTTF.priority);
            gen.writeNumberField('source', eachTTF.source);
            gen.writeNumberField('status', eachTTF.status);
            gen.writeStringField('subject', eachTTF.subject);
            gen.writeStringField('type', eachTTF.type);
            gen.writeStringField('description', eachTTF.description);
            gen.writeFieldName('custom_fields');
            gen.writeStartObject();
            gen.writeStringField('service_team', eachTTF.serviceTeam);
            gen.writeEndObject();
            gen.writeFieldName('tags');
            gen.writeStartArray();
            gen.writeString(eachTTF.tags);
            gen.writeEndArray();
            gen.writeEndObject();

            String jsonBody = gen.getAsString();
            System.debug('jsonBody: ' + jsonBody);
            
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:Freshservice');
        request.setBody(jsonBody);

        Http http = new Http();
        HttpResponse response = http.send(request);
        
        statusCodes.add(+response.getStatusCode());
        }
        return statusCodes;
    }
}