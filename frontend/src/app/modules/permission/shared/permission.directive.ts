import { FormGroup, ValidationErrors, } from '@angular/forms';

/**
 * Validates if at least one of the provided fields has a value.
 * Fields can only be of type number or string.
 * @param fields name of the form fields that should be checked
 * @source Florian Leitgeb <https://stackoverflow.com/a/52779734>
 */
export function atLeastOne(...fields: string[]) {
  return (fg: FormGroup): ValidationErrors | null => {
    return fields.some(fieldName => {
      const field = fg.get(fieldName).value;
      if (typeof field === 'number') {
        return field && field >= 0 ? true : false;
      } else if (typeof field === 'string') {
        return field && field.length > 0 ? true : false;
      } else if (typeof field === 'object') {
        return field && field.length > 0 ? true : false;
      } else {
        let fieldType = typeof field;
        console.log(`In atLeastOne Directive field type "${fieldType}" not implemented for field ${fieldName}.`)
      }
    })
      ? null
      : ({ atLeastOne: 'At least one field has to be provided.' } as ValidationErrors);
  };
}
