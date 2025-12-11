using System;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Data.SqlClient;
using System.Data;

namespace ProjetoFBD
{
    public partial class GPListForm : Form
    {
        private string userRole;
        private int selectedYear;
        private DataGridView? dgvGPs;
        private Panel? pnlActions;
        
        public GPListForm(string role, int year)
        {
            InitializeComponent();
            this.userRole = role;
            this.selectedYear = year;
            
            // Configuração básica
            this.Text = $"Grand Prix Events - {year} Season";
            this.Size = new Size(1000, 700);
            this.StartPosition = FormStartPosition.CenterScreen;
            
            // Adicionar controles
            SetupLayout();
            LoadGPData();
        }

        private void SetupLayout()
        {
            // Título
            Label lblTitle = new Label
            {
                Text = $"Grand Prix Events - {selectedYear} Season",
                Location = new Point(20, 20),
                Size = new Size(500, 30),
                Font = new Font("Arial", 16, FontStyle.Bold),
                ForeColor = Color.DarkBlue
            };
            this.Controls.Add(lblTitle);

            // DataGridView para mostrar os GPs
            dgvGPs = new DataGridView
            {
                Name = "dgvGPs",
                Location = new Point(20, 70),
                Size = new Size(940, 450),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                AllowUserToAddRows = false,
                ReadOnly = true,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                RowHeadersVisible = false
            };
            this.Controls.Add(dgvGPs);

            // Painel para ações (botões)
            pnlActions = new Panel
            {
                Location = new Point(20, 540),
                Size = new Size(400, 50),
                Anchor = AnchorStyles.Bottom | AnchorStyles.Left
            };
            this.Controls.Add(pnlActions);

            // Botão para ver detalhes do GP (sessões, resultados, etc.)
            Button btnViewDetails = CreateActionButton("View GP Details", new Point(0, 5));
            btnViewDetails.Click += btnViewDetails_Click;
            
            // Botão para fechar
            Button btnClose = CreateActionButton("Close", new Point(140, 5));
            btnClose.Click += (s, e) => this.Close();
            
            pnlActions.Controls.Add(btnViewDetails);
            pnlActions.Controls.Add(btnClose);
            
            // Para Staff, adicionar botões de administração
            if (this.userRole == "Staff")
            {
                Button btnAddGP = CreateActionButton("Add GP", new Point(280, 5));
                btnAddGP.Click += btnAddGP_Click;
                pnlActions.Controls.Add(btnAddGP);
                
                // Botão para editar GP selecionado
                Button btnEditGP = CreateActionButton("Edit GP", new Point(420, 5));
                btnEditGP.Click += btnEditGP_Click;
                pnlActions.Controls.Add(btnEditGP);
                
                // Aumentar tamanho do painel
                pnlActions.Size = new Size(560, 50);
            }
        }
        
        private Button CreateActionButton(string text, Point location)
        {
            Button btn = new Button 
            { 
                Text = text, 
                Location = location, 
                Size = new Size(130, 40), 
                BackColor = Color.FromArgb(0, 102, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                FlatAppearance = { BorderSize = 0 }
            };
            return btn;
        }

        private void LoadGPData()
{
    string connectionString = DbConfig.ConnectionString;
    
    // Lista de queries possíveis com diferentes combinações de nomes de colunas
    string[] queries = new string[]
    {
        // Tentativa 1: Nomes como você os forneceu
        @"
        SELECT 
            gp.NomeGP as [Grand Prix Name],
            c.Nome as [Circuit],
            gp.Ano_Temporada as [Season Year]
        FROM Grande_Prémio gp
        INNER JOIN Circuito c ON gp.ID_Circuito = c.ID
        WHERE gp.Ano_Temporada = @Year
        ORDER BY gp.DataCorrida ASC",
        
        // Tentativa 2: Nomes alternativos (sem acentos, etc.)
        @"
        SELECT 
            gp.NomeGP as GP_Name,
            c.Nome as Circuit_Name,
            gp.Ano_Temporada as Season_Year
        FROM Grande_Prémio gp
        INNER JOIN Circuito c ON gp.ID_Circuito = c.ID
        WHERE gp.Ano_Temporada = @Year
        ORDER BY gp.DataCorrida ASC",
        
        // Tentativa 3: Sem JOIN primeiro
        @"
        SELECT 
            NomeGP as GP_Name,
            Ano_Temporada as Season_Year
        FROM Grande_Prémio
        WHERE Ano_Temporada = @Year
        ORDER BY DataCorrida ASC",
        
        // Tentativa 4: Usando * para ver todas as colunas
        @"
        SELECT TOP 10 *
        FROM Grande_Prémio
        WHERE Ano_Temporada = @Year
        ORDER BY DataCorrida ASC"
    };
    
    DataTable gpTable = new DataTable();
    bool success = false;
    string lastError = "";
    
    for (int i = 0; i < queries.Length; i++)
    {
        try
        {
            Console.WriteLine($"Tentando query {i + 1}...");
            
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                SqlCommand command = new SqlCommand(queries[i], connection);
                command.Parameters.AddWithValue("@Year", selectedYear);
                
                SqlDataAdapter adapter = new SqlDataAdapter(command);
                gpTable.Clear();
                adapter.Fill(gpTable);
                
                success = true;
                Console.WriteLine($"✓ Query {i + 1} bem sucedida! {gpTable.Rows.Count} registros encontrados.");
                
                // Mostrar colunas retornadas
                Console.WriteLine("Colunas retornadas:");
                foreach (DataColumn column in gpTable.Columns)
                {
                    Console.WriteLine($"  - {column.ColumnName} ({column.DataType})");
                }
                
                break;
            }
        }
        catch (SqlException ex)
        {
            lastError = ex.Message;
            Console.WriteLine($"✗ Query {i + 1} falhou: {ex.Message}");
            
            // Se não for a última query, continue tentando
            if (i < queries.Length - 1)
            {
                continue;
            }
        }
    }
    
    if (!success)
    {
        string errorMsg = $"Não foi possível carregar dados dos GPs.\n\nÚltimo erro: {lastError}\n\n";
        errorMsg += "Por favor, verifique:\n";
        errorMsg += "1. Conexão com a base de dados\n";
        errorMsg += "2. Nomes das tabelas e colunas\n";
        errorMsg += "3. Permissões de acesso\n\n";
        errorMsg += "Clique em OK para ver a estrutura das tabelas.";
        
        return;
    }
    
    // Configurar o DataGridView
    if (dgvGPs != null)
    {
        dgvGPs.DataSource = gpTable;
        
        // Renomear cabeçalhos para ficarem bonitos
        foreach (DataGridViewColumn column in dgvGPs.Columns)
        {
            switch (column.Name)
            {
                case "GP_Name":
                case "NomeGP":
                    column.HeaderText = "Grand Prix Name";
                    column.Width = 200;
                    break;
                    
                case "Circuit_Name":
                case "Nome":
                    column.HeaderText = "Circuit";
                    column.Width = 150;
                    break;
                    
                case "Race_Date":
                case "DataCorrida":
                    column.HeaderText = "Race Date";
                    column.DefaultCellStyle.Format = "dd/MM/yyyy";
                    column.Width = 100;
                    break;
                    
                case "Season_Year":
                case "Ano_Temporada":
                    column.HeaderText = "Season";
                    column.Visible = false; // Esconder pois já sabemos o ano
                    break;
                    
                case "ID_Circuito":
                    column.Visible = false; // Esconder ID do circuito
                    break;
                    
                default:
                    // Para outras colunas que possam aparecer
                    if (column.Name.Contains("ID") || column.Name.ToLower().Contains("id"))
                    {
                        column.Visible = false;
                    }
                    break;
            }
        }
    }
    
    // Mostrar contagem de GPs
    if (dgvGPs != null && gpTable.Rows.Count > 0)
    {
        // Remover label anterior se existir
        foreach (Control control in this.Controls)
        {
            if (control is Label lbl && lbl.Text != null && lbl.Text.Contains("Total GPs:"))
            {
                this.Controls.Remove(control);
                break;
            }
        }
        
        Label lblCount = new Label
        {
            Text = $"Total GPs: {gpTable.Rows.Count}",
            Location = new Point(500, 540),
            Size = new Size(150, 30),
            Font = new Font("Arial", 10, FontStyle.Bold),
            Anchor = AnchorStyles.Bottom | AnchorStyles.Left
        };
        this.Controls.Add(lblCount);
    }
    else if (gpTable.Rows.Count == 0)
    {
        MessageBox.Show($"No Grand Prix events found for {selectedYear}.", 
            "No Data", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}

        private void btnViewDetails_Click(object? sender, EventArgs e)
{
    if (dgvGPs == null || dgvGPs.SelectedRows.Count == 0)
    {
        MessageBox.Show("Please select a Grand Prix first.", "No Selection", 
            MessageBoxButtons.OK, MessageBoxIcon.Information);
        return;
    }
    
    DataGridViewRow selectedRow = dgvGPs.SelectedRows[0];
    
    // Usar operador null-conditional e null-coalescing para evitar referências nulas
    string gpName = selectedRow.Cells["Grand Prix Name"]?.Value?.ToString() ?? "N/A";
    string circuitName = selectedRow.Cells["Circuit"]?.Value?.ToString() ?? "N/A";
    
    // Para a data, tratar especialmente
    object? dateValue = selectedRow.Cells["Race Date"]?.Value;
    string raceDate = dateValue is DateTime dateTimeValue ? 
        dateTimeValue.ToString("dd/MM/yyyy") : 
        (dateValue?.ToString() ?? "N/A");
    
    // Obter o ano da temporada da linha selecionada
    object? yearValue = selectedRow.Cells["Season Year"]?.Value;
    int seasonYear = yearValue != null && int.TryParse(yearValue.ToString(), out int year) ? 
        year : selectedYear;
    
    // Aqui você pode abrir um formulário para mostrar os detalhes do GP
    // Passando o nome do GP, circuito e data para identificar unicamente
    ShowGPDetails(gpName, circuitName, raceDate, seasonYear);
}

        private void btnAddGP_Click(object? sender, EventArgs e)
{
    if (this.userRole != "Staff")
    {
        MessageBox.Show("Only Staff members can add new Grand Prix events.", 
            "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        return;
    }
    
    // Abrir o GPForm para adicionar um novo GP para esta temporada
    try
    {
        // Use o construtor que realmente existe - apenas com userRole
        GPForm gpForm = new GPForm(this.userRole);
        
        // Quando o formulário for mostrado, podemos tentar pré-selecionar o ano
        // se o GPForm tiver um controle para selecionar o ano
        gpForm.Shown += (s, args) =>
        {
            // Você pode tentar definir o ano no formulário se tiver acesso aos controles
            // Isso depende de como seu GPForm está implementado
            
            // Exemplo 1: Se houver uma propriedade pública para definir o ano
            try
            {
                var property = gpForm.GetType().GetProperty("SelectedYear");
                if (property != null && property.CanWrite)
                {
                    property.SetValue(gpForm, selectedYear);
                }
            }
            catch
            {
                // Ignorar se não funcionar
            }
            
            // Exemplo 2: Mostrar mensagem informativa
            MessageBox.Show($"Creating GP for season {selectedYear}. Please ensure you select the correct year.", 
                "Season Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
        };
        
        if (gpForm.ShowDialog() == DialogResult.OK)
        {
            // Recarregar dados após adicionar
            LoadGPData();
        }
    }
    catch (Exception ex)
    {
        MessageBox.Show($"Error opening GP form: {ex.Message}", 
            "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
}

        private void btnEditGP_Click(object? sender, EventArgs e)
        {
            if (dgvGPs == null || dgvGPs.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select a Grand Prix to edit.", "No Selection", 
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            
            DataGridViewRow selectedRow = dgvGPs.SelectedRows[0];
            string gpName = selectedRow.Cells["Grand Prix Name"]?.Value?.ToString() ?? "Unknown GP";
            
            // Mensagem informativa (você precisaria implementar a edição propriamente dita)
            MessageBox.Show($"Would open edit form for: {gpName}\n\n" +
                           "You would need to pass the GP ID to the edit form.", 
                           "Edit GP", MessageBoxButtons.OK, MessageBoxIcon.Information);
            
            // Para implementar a edição, você precisaria:
            // 1. Buscar o ID do GP selecionado
            // 2. Abrir GPForm em modo edição
            // 3. Passar o ID e os dados atuais
        }

        private void ShowGPDetails(string gpName, string circuitName, string raceDate, int seasonYear)
{
    try
    {
        // Criar um formulário de detalhes mais completo
        Form detailsForm = new Form
        {
            Text = $"GP Details: {gpName} ({seasonYear})",
            Size = new Size(600, 400),
            StartPosition = FormStartPosition.CenterParent,
            FormBorderStyle = FormBorderStyle.FixedDialog,
            MaximizeBox = false,
            MinimizeBox = false
        };
        
        // Painel principal
        Panel mainPanel = new Panel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(20)
        };
        
        // Informações do GP
        Label lblGPInfo = new Label
        {
            Text = $"Grand Prix: {gpName}\n" +
                   $"Circuit: {circuitName}\n" +
                   $"Date: {raceDate}\n" +
                   $"Season: {seasonYear}",
            Location = new Point(20, 20),
            Size = new Size(500, 100),
            Font = new Font("Arial", 11)
        };
        
        // Se quiser buscar mais informações do banco de dados baseado no nome, data e ano
        string additionalInfo = GetGPAdditionalInfo(gpName, raceDate, seasonYear);
        
        Label lblAdditionalInfo = new Label
        {
            Text = additionalInfo,
            Location = new Point(20, 130),
            Size = new Size(500, 100),
            Font = new Font("Arial", 10)
        };
        
        // Label informativa sobre sessões
        Label lblSessionsInfo = new Label
        {
            Text = "Weekend Sessions:\n\n" +
                   "• Free Practice 1\n" +
                   "• Free Practice 2\n" +
                   "• Free Practice 3 (if applicable)\n" +
                   "• Qualifying\n" +
                   "• Race\n\n" +
                   "(Each session would have its own results table)",
            Location = new Point(20, 240),
            Size = new Size(500, 150),
            Font = new Font("Arial", 10)
        };
        
        // Botão para fechar
        Button btnCloseDetails = new Button
        {
            Text = "Close",
            Location = new Point(450, 320),
            Size = new Size(100, 30),
            DialogResult = DialogResult.OK
        };
        btnCloseDetails.Click += (s, e) => detailsForm.Close();
        
        mainPanel.Controls.Add(lblGPInfo);
        if (!string.IsNullOrEmpty(additionalInfo))
            mainPanel.Controls.Add(lblAdditionalInfo);
        mainPanel.Controls.Add(lblSessionsInfo);
        mainPanel.Controls.Add(btnCloseDetails);
        
        detailsForm.Controls.Add(mainPanel);
        detailsForm.AcceptButton = btnCloseDetails;
        detailsForm.ShowDialog();
    }
    catch (Exception ex)
    {
        MessageBox.Show($"Could not show GP details: {ex.Message}", 
            "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
}

private string GetGPAdditionalInfo(string gpName, string raceDate, int seasonYear)
{
    // Método opcional para buscar informações adicionais do banco de dados
    try
    {
        string connectionString = DbConfig.ConnectionString;
        string query = @"
            SELECT 
                COUNT(*) as SessionCount
            FROM Grande_Prémio gp
            WHERE gp.NomeGP = @GPName 
                AND gp.Ano_Temporada = @Year
                AND CONVERT(DATE, gp.DataCorrida) = CONVERT(DATE, @RaceDate)";
        
        using (SqlConnection connection = new SqlConnection(connectionString))
        {
            SqlCommand command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@GPName", gpName);
            command.Parameters.AddWithValue("@Year", seasonYear);
            command.Parameters.AddWithValue("@RaceDate", DateTime.Parse(raceDate));
            
            connection.Open();
            var result = command.ExecuteScalar();
            
            if (result != null && result != DBNull.Value)
            {
                return $"Found in database: Yes\nAssociated sessions could be shown here";
            }
        }
    }
    catch
    {
        // Ignorar erros - é apenas informação adicional
    }
    
    return string.Empty;
}

        // Método para atualizar a lista
        public void RefreshGPList()
        {
            // Limpar controles existentes (exceto título e DataGridView)
            foreach (Control control in this.Controls)
            {
                if (control is Label lbl && lbl.Text != null && lbl.Text.Contains("Total GPs:"))
                {
                    this.Controls.Remove(control);
                    break;
                }
            }
            
            LoadGPData();
        }
    }
}