using Common;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Text;
using System.Web;

namespace Common
{
    public static class UtilityWS
    {
        static bool ShowOriginalError = true;
        static UtilityWS()
        {
            // ShowOriginalError = System.IO.File.Exists(AppDomain.CurrentDomain.BaseDirectory + "\\originalerror.txt");
        }
        #region HandleError
        public static void HandleError(WSServiceResultBase result, Exception ex, string MethodName, string SupportMessage = "")
        {
            result.HasError = true;
            result.Messages.Clear();

            try
            {
                if (ex is SqlException && ShowOriginalError == false)
                {
                    SqlException sqlEx = (SqlException)ex;
                    if (sqlEx.Errors.Count > 0)
                    {
                        int ErrorNumber = sqlEx.Errors[0].Number;
                        if (ErrorNumber == 547)
                            result.Messages.Add(string.Format("Your action can't perform because it's used by one or more data", SupportMessage));
                        else if (ErrorNumber == 2601)
                            result.Messages.Add(string.Format("Your action can't perform because it's create duplicate value", SupportMessage));
                        else
                            result.Messages.Add(Messages.ShowErrorOccurred());
                    }
                }
                else
                {
                    if (ShowOriginalError == false)
                        result.Messages.Add(Messages.ShowErrorOccurred());
                    else
                        result.Messages.Add(ex.Message);
                }

                AddError(ex, MethodName, SupportMessage);
            }
            catch (Exception)
            {

            }

        }
        #endregion

        #region AddError
        #region AddError
        public static void AddError(Exception ex, string MethodName, string SupportMessage = "")
        {
            string extra = "";
            extra = "MethodName : " + MethodName + Environment.NewLine;
            extra += "SupportMessage : " + SupportMessage + Environment.NewLine;

            //if (CurrentDevice != null)
            //{
            //    extra += "Device ID : " + CurrentDevice.DeviceID.ToString() + Environment.NewLine;
            //}
            extra += "Error IP : " + GetClientIP() + Environment.NewLine;
            extra += "PostedValues : " + GetPostedValues();

            string ErrorMsg = ex.Message;
            string ErrorStackTrace = LoadError(ex);
            string Body = ErrorMsg + Environment.NewLine + ErrorStackTrace + extra;

            ErrorMgmt.AddError(ex, extra);
            // EmailClient.SendEmail("do-not-reply@alphaebarcode.com", "AlphaError-GSotWh_Extreme WS", "DSMFlj#5468sd", "mail.alphaebarcode.com", 25, false, "developer@alphaebarcode.com", "Error in GSoftWhExWS", Body.ToString().Replace("\n", "</br>"));
        }
        #endregion

        #region ReadHeader
        public static void ReadHeader()
        {
            System.ServiceModel.Web.WebOperationContext ctx = System.ServiceModel.Web.WebOperationContext.Current;
            if (ctx.IncomingRequest.Headers["did"] != null)
            {
                string request_header_value1 = ctx.IncomingRequest.Headers["did"].ToString();
            }
        }
        #endregion

        #region GetClientIP
        public static string GetClientIP()
        {
            OperationContext context = OperationContext.Current;
            Message m = context.RequestContext.RequestMessage;
            MessageProperties prop = context.IncomingMessageProperties;
            RemoteEndpointMessageProperty endpoint = prop[RemoteEndpointMessageProperty.Name] as RemoteEndpointMessageProperty;
            string ip = endpoint.Address;
            return ip;
        }
        #endregion

        #region GetPostedValues
        public static string GetPostedValues()
        {
            OperationContext context = OperationContext.Current;
            Message m = context.RequestContext.RequestMessage;


            var Properties = OperationContext.Current.IncomingMessageProperties;
            var property = Properties[HttpRequestMessageProperty.Name] as HttpRequestMessageProperty;
            string QueryString = property.QueryString;


            return m.ToString();
        }
        #endregion

        #region LoadError
        public static string LoadError(Exception objError)
        {
            StringBuilder lasterror = new StringBuilder();
            if (objError != null)
            {
                if (objError.Message != null)
                {
                    lasterror.AppendLine("Message:");
                    lasterror.AppendLine(objError.Message);
                    lasterror.AppendLine();
                }

                if (objError.InnerException != null)
                {
                    lasterror.AppendLine("InnerException:");
                    lasterror.AppendLine(objError.InnerException.ToString());
                    lasterror.AppendLine();
                }

                if (objError.Source != null)
                {
                    lasterror.AppendLine("Source:");
                    lasterror.AppendLine(objError.Source);
                    lasterror.AppendLine();
                }

                if (objError.StackTrace != null)
                {
                    lasterror.AppendLine("StackTrace:");
                    lasterror.AppendLine(objError.StackTrace);
                    lasterror.AppendLine();
                }
            }
            return lasterror.ToString();
        }
        #endregion
        #endregion

        #region IsNullOrEmpty
        public static bool IsNullOrEmpty(string value)
        {
            if (value == null)
                return true;
            if (string.IsNullOrEmpty(value))
                return true;
            if (value.Trim() == "")
                return true;
            return false;
        }
        #endregion

        #region ReadHeader
        public static string ReadHeader(string key)
        {
            System.ServiceModel.Web.WebOperationContext ctx = System.ServiceModel.Web.WebOperationContext.Current;
            if (ctx != null)
                if (ctx.IncomingRequest != null)
                    if (ctx.IncomingRequest.Headers[key] != null)
                    {
                        return ctx.IncomingRequest.Headers[key].ToString();
                    }
            return "";
        }
        #endregion

        public static string LogFileName = string.Empty;
        public readonly static string ErrorLogDirectory = AppDomain.CurrentDomain.BaseDirectory + "\\log\\";
        public static string ErrorLogFileName
        {
            get
            {
                if (string.IsNullOrEmpty(LogFileName))
                    LogFileName = "WSLog " + DateTime.Now.Ticks.ToString() + " .txt";
                return LogFileName;
            }
        }

        static object SyncObject = new object();
        public static void WriteLog(string log, string fname = "")
        {
            try
            {
                if (!System.IO.File.Exists(AppDomain.CurrentDomain.BaseDirectory + "\\debug.dbg"))
                {
                    return;
                }

                lock (SyncObject)
                {
                    if ((!Directory.Exists(ErrorLogDirectory)))
                    {
                        Directory.CreateDirectory(ErrorLogDirectory);
                    }
                    StreamWriter writer = default(StreamWriter);
                    string FileName = (fname == "") ? ErrorLogFileName : fname;
                    writer = new StreamWriter(ErrorLogDirectory + FileName, true);
                    writer.WriteLine(DateTime.Now.ToString() + " - " + log);
                    writer.Close();
                    writer.Dispose();
                }
            }
            catch (Exception ex)
            {

            }
            finally
            {

            }
        }
    }
}

