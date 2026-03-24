import { LightningElement, api } from 'lwc';

export default class RichTextAreaLWC extends LightningElement {
    @api value;
    @api label;
    handleChange(event) {
    this.value = event.target.value;
    }
}