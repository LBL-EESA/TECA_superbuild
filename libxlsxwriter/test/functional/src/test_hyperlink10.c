/*****************************************************************************
 * Test cases for libxlsxwriter.
 *
 * Test to compare output against Excel files.
 *
 * Copyright 2014-2016, John McNamara, jmcnamara@cpan.org
 *
 */

#include "xlsxwriter.h"

int main() {

    lxw_workbook  *workbook  = workbook_new("test_hyperlink10.xlsx");
    lxw_worksheet *worksheet = workbook_add_worksheet(workbook, NULL);
    lxw_format *format = workbook_add_format(workbook);

    format_set_underline(format, LXW_UNDERLINE_SINGLE);
    format_set_font_color(format, LXW_COLOR_RED);

    worksheet_write_url(worksheet, CELL("A1"), "http://www.perl.org/", format);

    return workbook_close(workbook);
}