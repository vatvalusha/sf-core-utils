import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import {
  getRecord,
  getFieldValue,
  createRecord,
  updateRecord
} from "lightning/uiRecordApi";

// Retention__c Object and Fields
import RETENTION_OBJECT from "@salesforce/schema/Retention__c";
import RETENTION_NAME from "@salesforce/schema/Retention__c.Name";
import TARGET_OBJECT from "@salesforce/schema/Retention__c.TargetObject__c";
import RETENTION_AGE from "@salesforce/schema/Retention__c.RetentionAge__c";
import RETENTION_UNIT from "@salesforce/schema/Retention__c.RetentionUnit__c";
import DATE_FIELD_API from "@salesforce/schema/Retention__c.DateFieldAPI__c";
import ACTIVE from "@salesforce/schema/Retention__c.Active__c";
import SIMULATE from "@salesforce/schema/Retention__c.Simulate__c";
import HARD_DELETE from "@salesforce/schema/Retention__c.HardDelete__c";
import RUN_METHOD from "@salesforce/schema/Retention__c.RunMethod__c";
import BATCH_FREQUENCY from "@salesforce/schema/Retention__c.BatchFrequency__c";
import BATCH_CHUNK_SIZE from "@salesforce/schema/Retention__c.BatchChunkSize__c";
import RECORD_LIMIT_PER_RUN from "@salesforce/schema/Retention__c.RecordLimitPerRun__c";
import FILTER_CONDITION from "@salesforce/schema/Retention__c.FilterCondition__c";

// Apex Methods
import getRetentionRuns from "@salesforce/apex/RetentionRuleEditorController.getRetentionRuns";
import validateRetentionRule from "@salesforce/apex/RetentionRuleEditorController.validateRetentionRule";
import getAvailableObjects from "@salesforce/apex/RetentionRuleEditorController.getAvailableObjects";

const RETENTION_FIELDS = [
  RETENTION_NAME,
  TARGET_OBJECT,
  RETENTION_AGE,
  RETENTION_UNIT,
  DATE_FIELD_API,
  ACTIVE,
  SIMULATE,
  HARD_DELETE,
  RUN_METHOD,
  BATCH_FREQUENCY,
  BATCH_CHUNK_SIZE,
  RECORD_LIMIT_PER_RUN,
  FILTER_CONDITION
];

export default class RetentionRuleEditor extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @track retentionRule = {};
  @track retentionRuns = [];
  @track errorMessage;
  @track successMessage;
  @track isLoading = false;
  @track targetObjectOptions = [];

  // Picklist Options
  retentionUnitOptions = [
    { label: "Day", value: "Day" },
    { label: "Month", value: "Month" },
    { label: "Year", value: "Year" }
  ];

  runMethodOptions = [
    { label: "Scheduled", value: "Scheduled" },
    { label: "On Demand", value: "OnDemand" }
  ];

  batchFrequencyOptions = [
    { label: "Daily", value: "Daily" },
    { label: "Weekly", value: "Weekly" },
    { label: "Monthly", value: "Monthly" }
  ];

  // Data table columns for retention runs
  runColumns = [
    { label: "Run Name", fieldName: "Name", type: "text" },
    { label: "Status", fieldName: "Status__c", type: "text" },
    { label: "Found", fieldName: "Found__c", type: "number" },
    { label: "Deleted", fieldName: "Deleted__c", type: "number" },
    { label: "Errors", fieldName: "Errors__c", type: "number" },
    {
      label: "Started At",
      fieldName: "StartedAt__c",
      type: "date",
      typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
      }
    },
    {
      label: "Report",
      fieldName: "ReportFileId__c",
      type: "url",
      typeAttributes: {
        label: { fieldName: "ReportFileName" },
        target: "_blank"
      }
    }
  ];

  connectedCallback() {
    this.initializeRetentionRule();
    if (this.recordId) {
      this.loadRetentionRuns();
    }
    this.loadTargetObjectOptions();
  }

  // Wire to get record data if recordId is provided
  @wire(getRecord, { recordId: "$recordId", fields: RETENTION_FIELDS })
  wiredRetention({ error, data }) {
    if (data) {
      this.retentionRule = {
        Id: data.id,
        Name: getFieldValue(data, RETENTION_NAME) || "",
        VAL1__TargetObject__c: getFieldValue(data, TARGET_OBJECT) || "",
        VAL1__RetentionAge__c: getFieldValue(data, RETENTION_AGE) || 1,
        VAL1__RetentionUnit__c: getFieldValue(data, RETENTION_UNIT) || "Month",
        VAL1__DateFieldAPI__c:
          getFieldValue(data, DATE_FIELD_API) || "CreatedDate",
        VAL1__Active__c: getFieldValue(data, ACTIVE) || true,
        VAL1__Simulate__c: getFieldValue(data, SIMULATE) || true,
        VAL1__HardDelete__c: getFieldValue(data, HARD_DELETE) || false,
        VAL1__RunMethod__c: getFieldValue(data, RUN_METHOD) || "Scheduled",
        VAL1__BatchFrequency__c:
          getFieldValue(data, BATCH_FREQUENCY) || "Weekly",
        VAL1__BatchChunkSize__c: getFieldValue(data, BATCH_CHUNK_SIZE) || 200,
        VAL1__RecordLimitPerRun__c:
          getFieldValue(data, RECORD_LIMIT_PER_RUN) || 10000,
        VAL1__FilterCondition__c: getFieldValue(data, FILTER_CONDITION) || ""
      };
    } else if (error) {
      this.handleError("Error loading retention rule", error);
    }
  }

  initializeRetentionRule() {
    if (!this.recordId) {
      this.retentionRule = {
        Name: "",
        VAL1__TargetObject__c: "",
        VAL1__RetentionAge__c: 1,
        VAL1__RetentionUnit__c: "Month",
        VAL1__DateFieldAPI__c: "CreatedDate",
        VAL1__Active__c: true,
        VAL1__Simulate__c: true,
        VAL1__HardDelete__c: false,
        VAL1__RunMethod__c: "Scheduled",
        VAL1__BatchFrequency__c: "Weekly",
        VAL1__BatchChunkSize__c: 200,
        VAL1__RecordLimitPerRun__c: 10000,
        VAL1__FilterCondition__c: ""
      };
    }
  }

  get showHistory() {
    return this.recordId && this.retentionRuns.length > 0;
  }

  handleInputChange(event) {
    const field = event.target.dataset.field;
    const value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;

    this.retentionRule = {
      ...this.retentionRule,
      [field]: value
    };

    // Clear messages when user makes changes
    this.clearMessages();
  }

  async handleSave() {
    await this.saveRecord(false);
  }

  async handleSaveAndNew() {
    await this.saveRecord(true);
  }

  async saveRecord(createNew) {
    this.isLoading = true;
    this.clearMessages();
    try {
      // console.log('BBB BEFORE VALIDATE');
      // Validate the rule first
      // await this.validateRule();
      // console.log('AAA AFTER VALIDATE');

      const fields = { ...this.retentionRule };
      delete fields.Id; // Remove Id for createRecord

      let result;
      if (this.recordId) {
        // Update existing record
        await updateRecord({
          fields: {
            Id: this.recordId,
            ...fields
          }
        });
        this.successMessage = "Retention rule updated successfully!";
      } else {
        // Create new record
        result = await createRecord({
          apiName: RETENTION_OBJECT.objectApiName,
          fields: fields
        });
        this.successMessage = "Retention rule created successfully!";

        if (createNew) {
          // Reset form for new record
          this.initializeRetentionRule();
        } else {
          // Navigate to the new record
          this.navigateToRecord(result.id);
        }
      }

      // Show success toast
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: this.successMessage,
          variant: "success"
        })
      );

      // Reload retention runs if we're viewing an existing record
      if (this.recordId) {
        this.loadRetentionRuns();
      }
    } catch (error) {
      this.handleError("Error saving retention rule", error);
    } finally {
      this.isLoading = false;
    }
  }

  async validateRule() {
    try {
      const isValid = await validateRetentionRule({
        retentionRule: this.retentionRule
      });

      if (!isValid) {
        throw new Error(
          "Retention rule validation failed. Please check your configuration."
        );
      }
    } catch (error) {
      throw new Error(
        `Validation error: ${error.body?.message || error.message}`
      );
    }
  }

  handleCancel() {
    if (this.recordId) {
      // Navigate back to record page
      this.navigateToRecord(this.recordId);
    } else {
      // Navigate to list view
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName: "Retention__c",
          actionName: "list"
        }
      });
    }
  }

  navigateToRecord(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Retention__c",
        actionName: "view"
      }
    });
  }

  async loadRetentionRuns() {
    try {
      this.retentionRuns = await getRetentionRuns({
        retentionId: this.recordId
      });
    } catch (error) {
      console.error("Error loading retention runs:", error);
    }
  }

  handleError(title, error) {
    console.error(title, error);
    this.errorMessage =
      error.body?.message || error.message || "An unknown error occurred";

    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: this.errorMessage,
        variant: "error"
      })
    );
  }

  clearMessages() {
    this.errorMessage = null;
    this.successMessage = null;
  }

  async loadTargetObjectOptions() {
    try {
      const objects = await getAvailableObjects();
      this.targetObjectOptions = objects.map((obj) => ({
        label: obj.label,
        value: obj.value
      }));
    } catch (error) {
      console.error("Error loading target object options:", error);
      // Fallback to empty array if loading fails
      this.targetObjectOptions = [];
    }
  }
}
