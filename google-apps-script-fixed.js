function doPost(e) {
  try {
    console.log('doPost called with e:', typeof e, JSON.stringify(e));
    
    // Parse the incoming data
    let data;
    
    if (e && e.postData && e.postData.contents) {
      // Real POST request from website
      console.log('Processing real POST data');
      data = JSON.parse(e.postData.contents);
    } else {
      // No valid data received
      throw new Error('No valid POST data received. e: ' + (e ? JSON.stringify(e) : 'undefined'));
    }

    console.log('Parsed data:', JSON.stringify(data));

    // Your Google Sheet ID - REPLACE THIS WITH YOUR ACTUAL SHEET ID
    const SHEET_ID = 'YOUR_SHEET_ID_HERE';
    
    if (SHEET_ID === 'YOUR_SHEET_ID_HERE') {
      throw new Error('Please replace YOUR_SHEET_ID_HERE with your actual Google Sheet ID');
    }
    
    try {
      // Open the Google Sheet
      const sheet = SpreadsheetApp.openById(SHEET_ID).getActiveSheet();
      console.log('Opened sheet successfully');
      
      // Add headers if first row is empty
      if (sheet.getLastRow() === 0) {
        sheet.getRange(1, 1, 1, 10).setValues([[
          'Timestamp', 'Product', 'Username', 'Email', 'Instagram', 
          'TikTok', 'YouTube', 'WhatsApp', 'Video Price', 'Free Shoot'
        ]]);
        console.log('Added headers to sheet');
      }
      
      // Add the data
      const rowData = [
        data.timestamp || new Date().toISOString(),
        data.product || 'Unknown',
        data.username || 'Not provided',
        data.email || 'Not provided',
        data.instagram || 'Not provided',
        data.tiktok || 'Not provided',
        data.youtube || 'Not provided',
        data.whatsapp || 'Not provided',
        data.videoPrice || 'Not provided',
        data.freeShoot || 'No'
      ];
      
      sheet.appendRow(rowData);
      console.log('Data saved to sheet:', rowData);
      
      // Send email notification
      const emailBody = `📋 NEW APPLICATION RECEIVED

🎯 Product: ${data.product}
👤 Username: ${data.username}
📧 Email: ${data.email}
📱 Instagram: ${data.instagram}
🎵 TikTok: ${data.tiktok}
📺 YouTube: ${data.youtube}
💬 WhatsApp: ${data.whatsapp}
💰 Video Price: $${data.videoPrice}
🎁 Free Shoot: ${data.freeShoot}
⏰ Timestamp: ${data.timestamp}

---
This application was submitted through Elite Influencer Community website.`;

      MailApp.sendEmail({
        to: 'voiflo.community@gmail.com',
        subject: `🎯 New Application: ${data.product}`,
        body: emailBody
      });
      
      console.log('Email sent successfully');
      
    } catch (sheetError) {
      console.error('Sheet/Email error:', sheetError);
      
      // Send email with error info
      MailApp.sendEmail({
        to: 'voiflo.community@gmail.com',
        subject: '🚨 Application Received (Sheet Error)',
        body: `An application was received but couldn't be saved to sheet:

${JSON.stringify(data, null, 2)}

Sheet Error: ${sheetError.toString()}

Sheet ID used: ${SHEET_ID}`
      });
      
      console.log('Error email sent');
    }
    
    // Return success response
    const response = {success: true, message: 'Data received and processed'};
    console.log('Returning response:', response);
    
    return ContentService
      .createTextOutput(JSON.stringify(response))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    console.error('Main error:', error.toString());
    
    // Send error notification email
    try {
      MailApp.sendEmail({
        to: 'voiflo.community@gmail.com',
        subject: '🚨 Form Submission Error',
        body: `Form submission failed:

Error: ${error.toString()}

Parameter e: ${e ? JSON.stringify(e, null, 2) : 'undefined'}

This error occurred in the Google Apps Script.`
      });
      console.log('Error notification email sent');
    } catch (emailError) {
      console.error('Failed to send error email:', emailError.toString());
    }
    
    const errorResponse = {success: false, error: error.toString()};
    console.log('Returning error response:', errorResponse);
    
    return ContentService
      .createTextOutput(JSON.stringify(errorResponse))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// Separate test function that directly tests the sheet and email
function testSheetAndEmail() {
  console.log('=== TESTING SHEET AND EMAIL FUNCTIONALITY ===');
  
  try {
    // Test data
    const testData = {
      product: 'Test Product - Manual Test',
      username: 'test_user_manual',
      email: 'test@example.com',
      instagram: 'https://instagram.com/test',
      tiktok: 'Not provided',
      youtube: 'Not provided', 
      whatsapp: '+1234567890',
      videoPrice: '100',
      freeShoot: 'yes',
      timestamp: new Date().toISOString()
    };
    
    console.log('Test data:', JSON.stringify(testData));
    
    // Your Google Sheet ID - REPLACE THIS
    const SHEET_ID = 'YOUR_SHEET_ID_HERE';
    
    if (SHEET_ID === 'YOUR_SHEET_ID_HERE') {
      throw new Error('❌ Please replace YOUR_SHEET_ID_HERE with your actual Google Sheet ID in the script');
    }
    
    // Test sheet access
    console.log('Testing sheet access...');
    const sheet = SpreadsheetApp.openById(SHEET_ID).getActiveSheet();
    console.log('✅ Sheet opened successfully');
    
    // Add headers if needed
    if (sheet.getLastRow() === 0) {
      sheet.getRange(1, 1, 1, 10).setValues([[
        'Timestamp', 'Product', 'Username', 'Email', 'Instagram', 
        'TikTok', 'YouTube', 'WhatsApp', 'Video Price', 'Free Shoot'
      ]]);
      console.log('✅ Headers added');
    }
    
    // Add test data
    const rowData = [
      testData.timestamp,
      testData.product,
      testData.username,
      testData.email,
      testData.instagram,
      testData.tiktok,
      testData.youtube,
      testData.whatsapp,
      testData.videoPrice,
      testData.freeShoot
    ];
    
    sheet.appendRow(rowData);
    console.log('✅ Test data added to sheet');
    
    // Test email
    console.log('Testing email...');
    MailApp.sendEmail({
      to: 'voiflo.community@gmail.com',
      subject: '✅ Test Email - Google Apps Script Working',
      body: `This is a test email to confirm your Google Apps Script is working correctly.

Test Data:
${JSON.stringify(testData, null, 2)}

If you received this email, your script is properly configured!

Timestamp: ${new Date().toISOString()}`
    });
    
    console.log('✅ Test email sent');
    console.log('=== TEST COMPLETED SUCCESSFULLY ===');
    
    return 'Test completed successfully! Check your Google Sheet and email.';
    
  } catch (error) {
    console.error('❌ Test failed:', error.toString());
    
    // Try to send error email
    try {
      MailApp.sendEmail({
        to: 'voiflo.community@gmail.com',
        subject: '❌ Google Apps Script Test Failed',
        body: `Your Google Apps Script test failed:

Error: ${error.toString()}

Please check:
1. Google Sheet ID is correct
2. Script has permissions to access sheets and send emails
3. Sheet exists and is accessible

Test run at: ${new Date().toISOString()}`
      });
      console.log('Error notification sent via email');
    } catch (emailError) {
      console.error('Failed to send error email:', emailError.toString());
    }
    
    throw error;
  }
}