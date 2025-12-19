using System;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Configuration; 
using System.Linq;
using System.IO;
using System.Collections.Generic;

namespace ProjetoFBD
{
    public partial class CircuitForm : Form
    {
        private string userRole;
        private SqlDataAdapter? dataAdapter; // Adaptador SQL
        private DataTable? circuitoTable;    // Tabela em memória

        // Bandeiras por país (emoji)
        private static readonly Dictionary<string, string> CountryFlags = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "Portugal", "🇵🇹" },
            { "Spain", "🇪🇸" }, { "Espanha", "🇪🇸" },
            { "Italy", "🇮🇹" }, { "Itália", "🇮🇹" },
            { "France", "🇫🇷" }, { "França", "🇫🇷" },
            { "UK", "🇬🇧" }, { "United Kingdom", "🇬🇧" }, { "Reino Unido", "🇬🇧" },
            { "Belgium", "🇧🇪" }, { "Bélgica", "🇧🇪" },
            { "Netherlands", "🇳🇱" }, { "Holanda", "🇳🇱" },
            { "Germany", "🇩🇪" }, { "Alemanha", "🇩🇪" },
            { "Austria", "🇦🇹" }, { "Áustria", "🇦🇹" },
            { "Monaco", "🇲🇨" }, { "Mónaco", "🇲🇨" },
            { "Hungary", "🇭🇺" }, { "Hungria", "🇭🇺" },
            { "Brazil", "🇧🇷" }, { "Brasil", "🇧🇷" },
            { "USA", "🇺🇸" }, { "United States", "🇺🇸" }, { "Estados Unidos", "🇺🇸" },
            { "Mexico", "🇲🇽" }, { "México", "🇲🇽" },
            { "Canada", "🇨🇦" }, { "Canadá", "🇨🇦" },
            { "Japan", "🇯🇵" }, { "Japão", "🇯🇵" },
            { "Singapore", "🇸🇬" }, { "Singapura", "🇸🇬" },
            { "Australia", "🇦🇺" }, { "Austrália", "🇦🇺" },
            { "UAE", "🇦🇪" }, { "United Arab Emirates", "🇦🇪" }, { "Emirados Árabes", "🇦🇪" },
            { "Bahrain", "🇧🇭" }, { "Bahrein", "🇧🇭" },
            { "Saudi Arabia", "🇸🇦" }, { "Arábia Saudita", "🇸🇦" },
            { "Qatar", "🇶🇦" }, { "Catar", "🇶🇦" },
            { "China", "🇨🇳" },
            { "South Korea", "🇰🇷" }, { "Coreia do Sul", "🇰🇷" },
            { "Russia", "🇷🇺" }, { "Rússia", "🇷🇺" },
            { "Azerbaijan", "🇦🇿" }, { "Azerbaijão", "🇦🇿" },
            { "Turkey", "🇹🇷" }, { "Turquia", "🇹🇷" }
        };

        private static string GetCountryFlag(string? country)
        {
            if (string.IsNullOrWhiteSpace(country))
                return "";
            
            if (CountryFlags.TryGetValue(country.Trim(), out string? flag))
                return flag + " ";
            
            return "";
        }

        // Parameterless constructor required by the Designer
        public CircuitForm() : this("Guest") { } 

        public CircuitForm(string role)
        {
            // Inicialização do formulário
            InitializeComponent(); 
            this.userRole = role;
            
            // UI Text in English
            this.Text = "Circuits Management";
            this.Size = new Size(1200, 700);
            this.StartPosition = FormStartPosition.CenterScreen;

            SetupCircuitsLayout();
            LoadCircuitoData();
        }

        private void SetupCircuitsLayout()
        {
            // Painel de ações (inferior)
            pnlStaffActions = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 50
            };
            this.Controls.Add(pnlStaffActions);

            // Grelha principal
            dgvCircuitos = new DataGridView
            {
                Name = "dgvCircuits",
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                // Default to ReadOnly. Staff access handled below.
                ReadOnly = true 
            };
            // Ajustes após binding
            dgvCircuitos.DataBindingComplete += DgvCircuitos_DataBindingComplete;
            // Aparência da grelha
            dgvCircuitos.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill; // Distribute columns
            dgvCircuitos.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.None;       // Keep row height fixed
            dgvCircuitos.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
            dgvCircuitos.ColumnHeadersDefaultCellStyle.WrapMode = DataGridViewTriState.False;
            dgvCircuitos.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter; // Center content
            dgvCircuitos.DefaultCellStyle.WrapMode = DataGridViewTriState.False;                 // No multiline text
            dgvCircuitos.RowHeadersVisible = true;
            this.Controls.Add(dgvCircuitos);

            // WinForms para Staff e Guest

            // Pesquisa (topo)
            pnlSearch = new Panel
            {
                Dock = DockStyle.Top,
                Height = 50,
                BackColor = Color.WhiteSmoke
            };
            this.Controls.Add(pnlSearch);

            // Barra de pesquisa
            lblSearch = new Label
            {
                Text = "Search:",
                AutoSize = true,
                Anchor = AnchorStyles.Top | AnchorStyles.Left
            };
            pnlSearch.Controls.Add(lblSearch);

            txtSearch = new TextBox
            {
                Size = new Size(380, 27),
                Anchor = AnchorStyles.Top | AnchorStyles.Left
            };
            txtSearch.TextChanged += txtSearch_TextChanged;
            pnlSearch.Controls.Add(txtSearch);

            // Posiciona pesquisa
            pnlSearch.SizeChanged += (s, e) => PositionSearchControls();
            PositionSearchControls();

            // Coluna de botão "Map"
            DataGridViewButtonColumn mapButtonColumn = new DataGridViewButtonColumn
            {
                Name = "MapColumn",
                HeaderText = "Map",
                Text = "View Map",
                UseColumnTextForButtonValue = true,
                AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill,
                FillWeight = 70
            };
            mapButtonColumn.MinimumWidth = 90;
            mapButtonColumn.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
            dgvCircuitos.Columns.Add(mapButtonColumn);
            dgvCircuitos.CellContentClick += dgvCircuitos_CellContentClick; // clique do botão

            // Botões
            Button btnSave = CreateActionButton("Save Changes", new Point(0, 5));
            Button btnAdd = CreateActionButton("Add New", new Point(140, 5));
            Button btnDelete = CreateActionButton("Delete Selected", new Point(280, 5));
            Button btnEdit = CreateActionButton("Edit Selected", new Point(420, 5));
            Button btnRefresh = CreateActionButton("Refresh", new Point(560, 5));
            Button btnUploadMap = CreateActionButton("Upload Map", new Point(700, 5));
            Button btnViewGPs = CreateActionButton("View GPs", new Point(840, 5));

            btnSave.Click += btnSave_Click;
            btnAdd.Click += btnAdd_Click;
            btnDelete.Click += btnDelete_Click;
            btnEdit.Click += btnEdit_Click;
            btnRefresh.Click += btnRefresh_Click;
            btnUploadMap.Click += btnUploadMap_Click;
            btnViewGPs.Click += btnViewGPs_Click;

            // Adiciona os botões
            pnlStaffActions.Controls.Add(btnSave);
            pnlStaffActions.Controls.Add(btnAdd);
            pnlStaffActions.Controls.Add(btnDelete);
            pnlStaffActions.Controls.Add(btnEdit);
            pnlStaffActions.Controls.Add(btnRefresh);
            pnlStaffActions.Controls.Add(btnUploadMap);
            pnlStaffActions.Controls.Add(btnViewGPs);
            
            // Permissões por perfil
            if (this.userRole == "Staff")
            {
                dgvCircuitos.ReadOnly = false; // Edição
                pnlStaffActions.Visible = true; // Mostra ações
                btnSave.Visible = btnAdd.Visible = btnDelete.Visible = btnEdit.Visible = btnUploadMap.Visible = btnRefresh.Visible = true;
                btnViewGPs.Visible = true;
            }
            else
            {
                // Guest: só leitura e apenas "View GPs"
                dgvCircuitos.ReadOnly = true;
                pnlStaffActions.Visible = true;
                btnSave.Visible = false;
                btnAdd.Visible = false;
                btnDelete.Visible = false;
                btnEdit.Visible = false;
                btnUploadMap.Visible = false;
                btnRefresh.Visible = false;
                btnViewGPs.Visible = true;
                // Centraliza botão único
                btnViewGPs.Location = new Point(0, 5);
            }
        }
        
        // Helper method for action buttons
        private Button CreateActionButton(string text, Point location)
        {
            Button btn = new Button
            {
                Text = text,
                Location = location,
                Size = new Size(130, 40),
                BackColor = Color.FromArgb(204, 0, 0),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            // configure FlatAppearance after construction (safer em object initializer)
            btn.FlatAppearance.BorderSize = 0;
            btn.Cursor = Cursors.Hand;
            return btn;
        }

        // -------------------------------------------------------------------------
        // UI event handlers
        // -------------------------------------------------------------------------

        private void btnEdit_Click(object? sender, EventArgs e)
        {
            if (userRole != "Staff") return;
            if (dgvCircuitos == null || dgvCircuitos.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select a row to edit.", "Edit", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            // Select first selected row and begin editing the first editable cell (excluding PK)
            var row = dgvCircuitos.SelectedRows[0];
            int editColIndex = -1;
            for (int i = 0; i < dgvCircuitos.Columns.Count; i++)
            {
                var col = dgvCircuitos.Columns[i];
                if (!col.ReadOnly && col.Visible)
                {
                    editColIndex = i; break;
                }
            }
            if (editColIndex >= 0)
            {
                dgvCircuitos.CurrentCell = row.Cells[editColIndex];
                dgvCircuitos.BeginEdit(true);
            }
            else
            {
                MessageBox.Show("No editable column found.", "Edit", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        // DATA ACCESS METHODS
private void LoadCircuitoData()
{
    try
    {
        if (dgvCircuitos == null)
        {
            MessageBox.Show("Grid not initialized.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        
        string connectionString = DbConfig.ConnectionString;
        if (string.IsNullOrEmpty(connectionString))
        {
            MessageBox.Show("Connection string not configured.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        string query = "SELECT ID_Circuito, Nome, Cidade, Pais, Comprimento_km, NumCurvas FROM Circuito";
        dataAdapter = new SqlDataAdapter(query, connectionString);
        circuitoTable = new DataTable();
        
        dataAdapter.Fill(circuitoTable);
        // Filtro case-insensitive
        circuitoTable.CaseSensitive = false;

        // Prefixa bandeira ao país
        if (circuitoTable != null && circuitoTable.Columns.Contains("Pais"))
        {
            foreach (DataRow row in circuitoTable.Rows)
            {
                if (row["Pais"] != DBNull.Value)
                {
                    string country = row["Pais"]?.ToString() ?? string.Empty;
                    string flag = GetCountryFlag(country);
                    if (!string.IsNullOrEmpty(flag))
                    {
                        row["Pais"] = flag + country;
                    }
                }
            }
        }

        dgvCircuitos.DataSource = circuitoTable;
        // Fonte única da grelha (WinForms)

        // Reapply any search filter after data reload
        ApplySearchFilter();

        // Tamanhos/alinhamentos
        if (dgvCircuitos.Columns != null && dgvCircuitos.Columns.Count > 0)
        {
            ConfigureGridColumns();
        }
        
        // Comandos de escrita só para Staff
        if (userRole == "Staff")
        {
            SqlCommandBuilder commandBuilder = new SqlCommandBuilder(dataAdapter);

            dataAdapter.InsertCommand = commandBuilder.GetInsertCommand(true);
            dataAdapter.UpdateCommand = commandBuilder.GetUpdateCommand(true);
            dataAdapter.DeleteCommand = commandBuilder.GetDeleteCommand(true);

            if (dataAdapter.InsertCommand != null)
            {
                // Garante retorno da PK
                dataAdapter.InsertCommand.UpdatedRowSource = UpdateRowSource.Both;
            }
        }
        }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error loading Circuit data: {ex.Message}", "Database Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }

        private static string RemoveCountryFlag(string? countryWithFlag)
        {
            if (string.IsNullOrWhiteSpace(countryWithFlag))
                return "";
            
            // Remove o emoji no início
            string cleaned = countryWithFlag.Trim();
            foreach (var flag in CountryFlags.Values)
            {
                if (cleaned.StartsWith(flag))
                {
                    cleaned = cleaned.Substring(flag.Length).Trim();
                    break;
                }
            }
            return cleaned;
        }

        private void txtSearch_TextChanged(object? sender, EventArgs e)
        {
            ApplySearchFilter();
        }

        private void ConfigureGridColumns()
        {
            if (dgvCircuitos == null || dgvCircuitos.Columns.Count == 0) return;

            // Ensure all columns are centered and not wrapping
            foreach (DataGridViewColumn col in dgvCircuitos.Columns)
            {
                col.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
                col.DefaultCellStyle.WrapMode = DataGridViewTriState.False;
                if (col.AutoSizeMode != DataGridViewAutoSizeColumnMode.Fill)
                    col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            }

            // Adjust relative widths (FillWeight) and minimum widths
            void SetWeights(string name, float weight, int minWidth)
            {
                var c = dgvCircuitos.Columns[name];
                if (c != null)
                {
                    c.FillWeight = weight;
                    c.MinimumWidth = minWidth;
                }
            }

            SetWeights("ID_Circuito", 90, 90);
            SetWeights("Nome", 220, 220);          // Give more space to avoid two lines
            SetWeights("Cidade", 130, 120);
            SetWeights("Pais", 160, 140);
            SetWeights("Comprimento_km", 130, 120);
            SetWeights("NumCurvas", 110, 100);
            SetWeights("MapColumn", 80, 90);
        }

        private void PositionSearchControls()
        {
            if (pnlSearch == null || txtSearch == null || lblSearch == null) return;
            int margin = 12;
            int txtWidth = Math.Min(350, Math.Max(200, pnlSearch.ClientSize.Width / 4));
            txtSearch.Size = new Size(txtWidth, txtSearch.Height);
            int centerY = (pnlSearch.Height - txtSearch.Height) / 2;
            
            int lblWidth = lblSearch.PreferredWidth + 6;
            int startX = Math.Max(margin, 20); // Start at left with padding
            
            lblSearch.Location = new Point(startX, centerY);
            txtSearch.Location = new Point(startX + lblWidth, centerY);
        }

        private void ApplySearchFilter()
        {
            if (circuitoTable == null) return;
            string term = txtSearch?.Text?.Trim() ?? string.Empty;
            if (string.IsNullOrEmpty(term))
            {
                circuitoTable.DefaultView.RowFilter = string.Empty;
                return;
            }

            string escaped = term.Replace("'", "''");
            string filter =
                $"Convert([Nome], 'System.String') LIKE '%{escaped}%' " +
                $"OR Convert([Cidade], 'System.String') LIKE '%{escaped}%' " +
                $"OR Convert([Pais], 'System.String') LIKE '%{escaped}%'";

            circuitoTable.DefaultView.RowFilter = filter;
        }

        // Ajusta colunas após binding
        private void DgvCircuitos_DataBindingComplete(object? sender, DataGridViewBindingCompleteEventArgs e)
        {
            if (dgvCircuitos == null || dgvCircuitos.Columns == null || dgvCircuitos.Columns.Count == 0)
                return;

            // Hide internal ID column from view
            if (dgvCircuitos.Columns.Contains("ID_Circuito"))
            {
                var idCol = dgvCircuitos.Columns["ID_Circuito"];
                if (idCol != null)
                {
                    idCol.Visible = false;
                }
            }

            // Cabeçalhos em inglês e fonte para emojis
            var nomeColumn = dgvCircuitos.Columns["Nome"]; if (nomeColumn != null) nomeColumn.HeaderText = "Name";
            var cidadeColumn = dgvCircuitos.Columns["Cidade"]; if (cidadeColumn != null) cidadeColumn.HeaderText = "City";
            var paisColumn = dgvCircuitos.Columns["Pais"]; 
            if (paisColumn != null)
            {
                paisColumn.HeaderText = "Country";
                try { paisColumn.DefaultCellStyle.Font = new Font("Segoe UI Emoji", dgvCircuitos.Font.Size); } catch {}
            }
            var comprimentoColumn = dgvCircuitos.Columns["Comprimento_km"]; if (comprimentoColumn != null) comprimentoColumn.HeaderText = "Length (km)";
            var numCurvasColumn = dgvCircuitos.Columns["NumCurvas"]; if (numCurvasColumn != null) numCurvasColumn.HeaderText = "Num Corners";

            // Tamanho/alinhamento
            ConfigureGridColumns();
        }
        
        
private void btnSave_Click(object? sender, EventArgs e)
{
    if (dataAdapter != null && circuitoTable != null && userRole == "Staff")
    {
        string connectionString = DbConfig.ConnectionString;

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            MessageBox.Show("Connection string is not configured.", "Configuration Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        // Abre ligação e confirma edição
        using (SqlConnection connection = new SqlConnection(connectionString))
        {
            try
            {
                dgvCircuitos.EndEdit(); 
                
                // Remove bandeiras antes de gravar
                if (circuitoTable.Columns.Contains("Pais"))
                {
                    foreach (DataRow row in circuitoTable.Rows)
                    {
                        if (row["Pais"] != DBNull.Value && row["Pais"] != null)
                        {
                            row["Pais"] = RemoveCountryFlag(row["Pais"].ToString());
                        }
                    }
                }
                
                // Associa comandos à ligação
                if (dataAdapter.InsertCommand != null) dataAdapter.InsertCommand.Connection = connection;
                if (dataAdapter.UpdateCommand != null) dataAdapter.UpdateCommand.Connection = connection;
                if (dataAdapter.DeleteCommand != null) dataAdapter.DeleteCommand.Connection = connection;

                connection.Open();
                
                // Grava alterações
                int rowsAffected = dataAdapter.Update(circuitoTable); 
                
                MessageBox.Show($"{rowsAffected} rows saved successfully!", "Success");
                circuitoTable.AcceptChanges();
                
                // Recarrega dados (volta a aplicar bandeiras)
                LoadCircuitoData();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving data: {ex.Message}", "Save Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                circuitoTable.RejectChanges(); 
            }
        } 
    }
}
        

private void btnAdd_Click(object? sender, EventArgs e)
{
    
    if (circuitoTable != null && userRole == "Staff")
    {
        // Adiciona uma nova linha no topo
        DataRow newRow = circuitoTable.NewRow();
        circuitoTable.Rows.InsertAt(newRow, 0);
        // Foca a primeira célula editável
        if (dgvCircuitos.Rows.Count > 0 && dgvCircuitos.Columns.Contains("Nome"))
        {
            dgvCircuitos.CurrentCell = dgvCircuitos.Rows[0].Cells["Nome"]; // Assumimos que 'Nome' é a primeira célula editável
                // Inicia edição
            dgvCircuitos.BeginEdit(true);
        }
    }
}

// Ficheiro: CircuitForm.cs

private void btnDelete_Click(object? sender, EventArgs e)
{
    // Só Staff e com seleção válida
    if (userRole == "Staff" && dgvCircuitos.SelectedRows.Count > 0 && circuitoTable != null)
    {
        // Confirmação
        DialogResult dialogResult = MessageBox.Show(
            "Are you sure you want to delete the selected row(s)? This action cannot be undone.", 
            "Confirm Deletion", 
            MessageBoxButtons.YesNo, 
            MessageBoxIcon.Warning);

        if (dialogResult == DialogResult.Yes)
        {
            try
            {
                // Percorre linhas selecionadas (ordem inversa)
                foreach (DataGridViewRow row in dgvCircuitos.SelectedRows.Cast<DataGridViewRow>().OrderByDescending(r => r.Index))
                {
                    // Obtém a DataRow correspondente
                    DataRow? dataRow = (row.DataBoundItem as DataRowView)?.Row;
                    
                    if (dataRow != null)
                    {
                        // Marca para eliminação
                        dataRow.Delete();
                    }
                }
                
                // Grava alterações
                btnSave_Click(sender, e); 
                
                // Recarrega os dados (opcional, mas garante que a visualização é atualizada)
                // LoadCircuitoData(); 
            }
            catch (SqlException sqlEx)
            {
                // FK em uso
                if (sqlEx.Message.Contains("REFERENCE constraint") || sqlEx.Message.Contains("FK_"))
                {
                    MessageBox.Show(
                        "Cannot delete this circuit because it is being used by one or more Grand Prix races.\n\n" +
                        "Please remove or reassign the affected Grand Prix races first, then try deleting the circuit again.",
                        "Circuit In Use",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Warning);
                }
                else
                {
                    MessageBox.Show($"Database error during deletion: {sqlEx.Message}", "Deletion Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                circuitoTable.RejectChanges(); // Reverte em erro
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error during deletion: {ex.Message}", "Deletion Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                circuitoTable.RejectChanges(); // Reverte em erro
            }
        }
    }
}

// No CircuitForm.cs (Adicione junto dos outros métodos de evento, ex: btnSave_Click)

private void btnRefresh_Click(object? sender, EventArgs e)
{
    // Confirma alterações pendentes
    if (circuitoTable != null && circuitoTable.GetChanges() != null)
    {
        DialogResult result = MessageBox.Show(
            "You have unsaved changes. Do you want to discard them and refresh the data?",
            "Unsaved Changes",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning);

        if (result == DialogResult.Yes)
        {
            circuitoTable.RejectChanges();
            LoadCircuitoData(); // Recarrega dados
            ApplySearchFilter();
        }
    }
    else
    {
        LoadCircuitoData(); // Sem alterações, recarrega
        ApplySearchFilter();
    }
}
        

        private void dgvCircuitos_CellContentClick(object? sender, DataGridViewCellEventArgs e)
        {
            // Só reage aos cliques na coluna do botão
            var mapColumn = dgvCircuitos.Columns["MapColumn"];
            if (e.RowIndex >= 0 && mapColumn != null && e.ColumnIndex == mapColumn.Index)
            {
                // Nome do circuito na linha
                string circuitName = dgvCircuitos.Rows[e.RowIndex].Cells["Nome"].Value?.ToString() ?? string.Empty;

                if (!string.IsNullOrEmpty(circuitName))
                {
                    ShowMapImage(circuitName);
                }
            }
        }

        private void btnUploadMap_Click(object? sender, EventArgs e)
        {
            if (userRole != "Staff")
            {
                MessageBox.Show("Only Staff members can upload circuit maps.", "Access Denied",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (dgvCircuitos == null || dgvCircuitos.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select a circuit first.", "No Selection",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            string circuitName = dgvCircuitos.SelectedRows[0].Cells["Nome"].Value?.ToString() ?? string.Empty;

            if (string.IsNullOrWhiteSpace(circuitName))
            {
                MessageBox.Show("The selected circuit has no name. Please add a name first.", "Invalid Circuit",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // Escolhe imagem a carregar
            using (OpenFileDialog openFileDialog = new OpenFileDialog())
            {
                openFileDialog.Title = "Select Circuit Map Image";
                openFileDialog.Filter = "Image Files|*.png;*.jpg;*.jpeg;*.bmp;*.gif|PNG Files|*.png|JPEG Files|*.jpg;*.jpeg|All Files|*.*";
                openFileDialog.FilterIndex = 1;

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        // Garante pasta de mapas
                        string mapsFolderPath = Path.Combine(Application.StartupPath, @"..\..\..\mapasCircuitos");
                        string fullMapsFolderPath = Path.GetFullPath(mapsFolderPath);

                        if (!Directory.Exists(fullMapsFolderPath))
                        {
                            Directory.CreateDirectory(fullMapsFolderPath);
                        }

                        // Nome do ficheiro: circuito + .png
                        string fileName = circuitName.Replace(' ', '_') + ".png";
                        string destinationPath = Path.Combine(fullMapsFolderPath, fileName);

                        // Se já existe, pergunta se substitui
                        if (File.Exists(destinationPath))
                        {
                            DialogResult result = MessageBox.Show(
                                $"A map already exists for '{circuitName}'.\n\nDo you want to replace it?",
                                "Replace Existing Map",
                                MessageBoxButtons.YesNo,
                                MessageBoxIcon.Question);

                            if (result != DialogResult.Yes)
                            {
                                return;
                            }

                            // Remove antigo
                            File.Delete(destinationPath);
                        }

                        // Copia imagem
                        File.Copy(openFileDialog.FileName, destinationPath, true);

                        MessageBox.Show($"Map uploaded successfully for '{circuitName}'!\n\nLocation: {destinationPath}",
                            "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error uploading map: {ex.Message}", "Upload Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void btnViewGPs_Click(object? sender, EventArgs e)
        {
            if (dgvCircuitos == null || dgvCircuitos.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select a circuit first.", "No Selection", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            DataGridViewRow row = dgvCircuitos.SelectedRows[0];
            object? idValue = dgvCircuitos.Columns.Contains("ID_Circuito") ? row.Cells["ID_Circuito"].Value : null;
            object? nameValue = dgvCircuitos.Columns.Contains("Nome") ? row.Cells["Nome"].Value : null;

            if (idValue == null || idValue == DBNull.Value || string.IsNullOrWhiteSpace(idValue.ToString()))
            {
                MessageBox.Show("Selected circuit has no valid ID.", "Invalid Circuit", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            int circuitId = Convert.ToInt32(idValue);
            string circuitName = nameValue?.ToString() ?? "Circuit";

            // Open GP list filtered by this circuit
            GPListForm gpList = new GPListForm(this.userRole, circuitId, circuitName);
            gpList.ShowDialog();
        }

        private void ShowMapImage(string circuitName)
        {
            try
            {
                // Converte o nome do circuito para o formato do nome do ficheiro (substitui espaços por underscores)
                string imageName = circuitName.Replace(' ', '_') + ".png";

                // Constrói o caminho para a imagem. Assume que a pasta 'mapasCircuitos' está na raiz do projeto.
                // O executável corre em 'IMPLEMENTAÇÃO/bin/Debug/netX.X-windows', por isso subimos 3 níveis para a pasta 'IMPLEMENTAÇÃO'.
                string relativePath = @"..\..\..\mapasCircuitos\" + imageName;
                string fullPath = Path.GetFullPath(Path.Combine(Application.StartupPath, relativePath));


                if (File.Exists(fullPath))
                {
                    // Form para mostrar mapa
                    using (Form mapForm = new Form())
                    {
                        mapForm.Text = "Map: " + circuitName;
                        mapForm.Size = new Size(800, 600);
                        mapForm.StartPosition = FormStartPosition.CenterParent;

                        PictureBox pictureBox = new PictureBox();
                        pictureBox.Dock = DockStyle.Fill;
                        pictureBox.Load(fullPath); // Load é mais seguro que Image.FromFile
                        pictureBox.SizeMode = PictureBoxSizeMode.Zoom;

                        mapForm.Controls.Add(pictureBox);
                        mapForm.ShowDialog();
                    }
                }
                else
                {
                    MessageBox.Show($"Map not found for circuit: {circuitName}\n\nPath checked:\n{fullPath}", "Map Not Found", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error showing map:\n" + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}