package `in`.bharatonepay.bharat_one_pay_app

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "in.bharatonepay/contacts"
    private val PICK_CONTACT_REQUEST = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickContact") {
                pendingResult = result
                try {
                    val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                    startActivityForResult(intent, PICK_CONTACT_REQUEST)
                } catch (e: Exception) {
                    pendingResult?.error("UNAVAILABLE", e.localizedMessage, null)
                    pendingResult = null
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_CONTACT_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val contactUri: Uri? = data.data
                if (contactUri != null) {
                    val projection = arrayOf(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER
                    )
                    var cursor: Cursor? = null
                    try {
                        cursor = contentResolver.query(contactUri, projection, null, null, null)
                        if (cursor != null && cursor.moveToFirst()) {
                            val nameIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                            val numberIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                            val name = if (nameIdx != -1) cursor.getString(nameIdx) else ""
                            var number = if (numberIdx != -1) cursor.getString(numberIdx) else ""
                            // Clean phone number (remove spaces, hyphens, brackets, +91)
                            number = number.replace(Regex("[^0-9]"), "")
                            if (number.length > 10 && number.startsWith("91")) {
                                number = number.substring(number.length - 10)
                            }
                            pendingResult?.success(mapOf("name" to name, "phone" to number))
                            pendingResult = null
                            return
                        }
                    } catch (e: Exception) {
                        pendingResult?.error("ERROR", e.localizedMessage, null)
                        pendingResult = null
                        return
                    } finally {
                        cursor?.close()
                    }
                }
            }
            pendingResult?.success(null)
            pendingResult = null
        }
    }
}
