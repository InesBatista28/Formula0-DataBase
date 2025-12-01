using System;
using System.Windows.Forms;
using System.Drawing;
using Microsoft.Data.SqlClient;
namespace ProjetoFBD
{
    public partial class LoginForm : Form
    {
        private bool areFieldsVisible = false;

        private const string connectionString =
    "Server=tcp:mednat.ieeta.pt\\SQLSERVER,8101;" +
    "Database=p3g9;" +
    "User Id=p3g9;" +
    "Password=MQ_IB_FBD_2526;" +
    "TrustServerCertificate=True;";

        public LoginForm()
        {
            InitializeComponent(); 
            
            this.StartPosition = FormStartPosition.CenterScreen;
            
            this.btnStaff.Click += new System.EventHandler(this.btnStaff_Click);
            this.btnGuest.Click += new System.EventHandler(this.btnGuest_Click);
            this.btnVoltar.Click += new System.EventHandler(this.btnVoltar_Click);
            
            this.btnVoltar.Visible = false; 
        }


        
        private void btnStaff_Click(object? sender, EventArgs e) 
        {
            if (!areFieldsVisible)
            {
                this.SuspendLayout();
                
                pnlStaffFields.Visible = true;
                areFieldsVisible = true;
                btnStaff.Text = "CONTINUAR"; 
                
                btnGuest.Visible = false; 
                btnVoltar.Visible = true; 
                
                btnVoltar.Location = new Point(80, 340);
                btnStaff.Location = new Point(250, 340); 
                
                this.ResumeLayout(false);
            }
            else
            {
                AuthenticateStaff(txtUsername.Text, txtPassword.Text);
            }
        }

        private void btnVoltar_Click(object? sender, EventArgs e)
        {
            this.SuspendLayout();

            pnlStaffFields.Visible = false;
            areFieldsVisible = false;
            
            btnStaff.Text = "STAFF";
            btnStaff.Location = new Point(80, 270); 
            btnGuest.Location = new Point(250, 270); 
            
            btnGuest.Visible = true;
            btnVoltar.Visible = false; 

            this.ResumeLayout(false);
        }
        
        private void btnGuest_Click(object? sender, EventArgs e) 
        {
            OpenHomePage("Guest");
        }

        private void AuthenticateStaff(string staffIdText, string password)
{

    if (!int.TryParse(staffIdText.Trim(), out int staffId))
    {
        MessageBox.Show("O Staff ID deve ser um número.", "Erro", MessageBoxButtons.OK, MessageBoxIcon.Error);
        txtUsername.Focus();
        return;
    }

    string cleanedPassword = password.Trim();

    string query = "SELECT COUNT(1) FROM Staff WHERE StaffID = @StaffID AND Password = @Password";

    using (SqlConnection connection = new SqlConnection(connectionString))
    using (SqlCommand command = new SqlCommand(query, connection))
    {
        try
        {
            command.Parameters.AddWithValue("@StaffID", staffId);
            command.Parameters.AddWithValue("@Password", cleanedPassword);

            connection.Open();

            int count = (int)command.ExecuteScalar();

            if (count == 1)
            {
                OpenHomePage("Staff");
            }
            else
            {
                MessageBox.Show("Staff ID ou Password incorretos.", 
                    "Erro de Login", MessageBoxButtons.OK, MessageBoxIcon.Error);

                txtPassword.Clear();
                txtUsername.Focus();
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Erro na Base de Dados: {ex.Message}",
                "Erro Crítico", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}


        private void OpenHomePage(string userRole)
        {
            MessageBox.Show($"Login bem-sucedido como {userRole}. PRÓXIMA TELA: HOME PAGE.", "Sucesso!");
            this.Close(); 
        }
    }
}